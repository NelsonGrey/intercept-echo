import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../content/challenge.dart';
import '../gamecenter/fake_game_center_progress_service.dart';
import '../gamecenter/game_center_progress_service.dart';
import '../gamecenter/games_services_progress_service.dart';
import '../settings/difficulty_setting.dart';
import 'puzzle_factory.dart';
import 'transmission.dart';

enum TransmissionStatus { playing, decoded, lost }

/// Scoring. Kept together so tuning after playtests is one place.
class InterceptScoring {
  const InterceptScoring._();

  static const signalBars = 4;
  static const perLetter = 100;
  static const perSpareMove = 20;

  /// Per distinct letter still hidden when the message is guessed.
  static const perGuessedLetter = 150;

  /// Cost of each Test after the first in a letter puzzle (the first is
  /// free).
  static const testCost = 1;

  /// Flat bonus for cracking a letter with Rotate as well as Shift — the
  /// extra operations `advanced` transmissions unlock once a player has
  /// shown they can shift reliably (see transmission.dart). Added before
  /// the difficulty multiplier, like [perSpareMove].
  static const advancedBonus = 40;

  /// Letters cracked with fewer place values on screen score more, rounded
  /// down — the harder the difficulty, the bigger the multiplier. The
  /// early-guess bonus is never multiplied.
  static const Map<Difficulty, double> crackMultiplier = {
    Difficulty.easy: 1.0,
    Difficulty.normal: 1.25,
    Difficulty.hard: 1.5,
  };
}

/// The player's progress through the Intercept campaign: which
/// transmission they are on, what they have cracked, their signal bars and
/// score. The transmission index and total score persist; the state of a
/// half-decoded message does not (a relaunch restarts that message).
class InterceptRun extends ChangeNotifier {
  InterceptRun({List<Transmission>? campaign, GameCenterProgressService? progress})
    : campaign = campaign ?? transmissions,
      _progress = progress ?? _defaultProgress();

  static GameCenterProgressService _defaultProgress() =>
      (Platform.isIOS || Platform.isMacOS)
      ? GamesServicesProgressService()
      : FakeGameCenterProgressService();

  final List<Transmission> campaign;
  final GameCenterProgressService _progress;

  static const _indexKey = 'intercept.index';
  static const _scoreKey = 'intercept.score';

  SharedPreferences? _prefs;
  int _index = 0;
  int _totalScore = 0;
  int _transmissionScore = 0;
  int _bars = InterceptScoring.signalBars;
  int _guessBonus = 0;
  final Set<String> _revealed = {};
  final Map<String, int> _attempts = {};
  TransmissionStatus _status = TransmissionStatus.playing;

  int get index => _index;
  int get totalScore => _totalScore;
  int get transmissionScore => _transmissionScore;
  int get bars => _bars;
  int get guessBonus => _guessBonus;
  Set<String> get revealed => Set.unmodifiable(_revealed);
  TransmissionStatus get status => _status;

  /// True once every transmission has been decoded.
  bool get campaignComplete => _index >= campaign.length;

  Transmission get current => campaign[_index];

  List<String> get hiddenLetters =>
      current.distinctLetters.where((l) => !_revealed.contains(l)).toList();

  /// Letters the player has cracked, with the number that decoded each —
  /// the evidence for working out a keyed transmission's cipher.
  Map<String, int> get crackedCodes => {
    for (final l in current.distinctLetters)
      if (_revealed.contains(l)) l: current.cipher.codeFor(l),
  };

  Future<void> load() async {
    final prefs = _prefs = await SharedPreferences.getInstance();
    _index = (prefs.getInt(_indexKey) ?? 0).clamp(0, campaign.length);
    _totalScore = prefs.getInt(_scoreKey) ?? 0;
    await _reconcileCloudProgress();
    _resetMessage();
    notifyListeners();
  }

  /// Merges in Game Center's cloud save (iCloud-backed on iOS): whichever
  /// of local/cloud is further ahead on each field wins, since both only
  /// move forward during normal play — safe even if this is a fresh
  /// install syncing an existing player's progress from another device.
  /// Best-effort: a missing or unreadable cloud save just keeps local.
  Future<void> _reconcileCloudProgress() async {
    final raw = await _progress.loadCloudProgress();
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final cloudIndex = (decoded['index'] as num?)?.toInt() ?? 0;
      final cloudScore = (decoded['score'] as num?)?.toInt() ?? 0;
      _index = (_index > cloudIndex ? _index : cloudIndex).clamp(
        0,
        campaign.length,
      );
      _totalScore = _totalScore > cloudScore ? _totalScore : cloudScore;
    } catch (_) {
      // Malformed/foreign save data — ignore, keep local.
    }
  }

  /// "Crack next letter": the first hidden letter in reading order.
  String? get nextLetter => hiddenLetters.isEmpty ? null : hiddenLetters.first;

  /// The puzzle for [letter]; a fresh one after each failed attempt.
  Challenge puzzleFor(String letter) => PuzzleFactory.build(
    transmissionIndex: _index,
    transmission: current,
    letter: letter,
    attempt: _attempts[letter] ?? 0,
  );

  void recordCrack(
    String letter, {
    required int spareMoves,
    int pointsSpent = 0,
    Difficulty difficulty = Difficulty.easy,
    bool advanced = false,
  }) {
    if (_status != TransmissionStatus.playing || _revealed.contains(letter)) {
      return;
    }
    _revealed.add(letter);
    final earned =
        InterceptScoring.perLetter +
        InterceptScoring.perSpareMove * spareMoves +
        (advanced ? InterceptScoring.advancedBonus : 0);
    final scaled = (earned * InterceptScoring.crackMultiplier[difficulty]!)
        .floor();
    // Net in one step, so Test costs are paid even from a score of 0.
    _award(scaled - pointsSpent);
    if (hiddenLetters.isEmpty) {
      _status = TransmissionStatus.decoded;
      _onTransmissionDecoded();
    }
    if (advanced) {
      unawaited(
        _progress.unlockAchievement(GameCenterIds.achievementUsedRotate),
      );
    }
    _persist();
    notifyListeners();
  }

  /// A failed or abandoned letter puzzle: lose a bar, and the next attempt
  /// at that letter gets a new puzzle.
  void recordFailure(String letter, {int pointsSpent = 0}) {
    if (_status != TransmissionStatus.playing) return;
    _award(-pointsSpent);
    _attempts[letter] = (_attempts[letter] ?? 0) + 1;
    _loseBar();
    notifyListeners();
  }

  /// Guess the whole message. Right: every hidden letter is revealed and
  /// scores the early-guess bonus. Wrong: lose a bar. Spaces and case are
  /// ignored.
  bool guess(String attempt) {
    if (_status != TransmissionStatus.playing) return false;
    String norm(String s) => s.toUpperCase().replaceAll(RegExp('[^A-Z]'), '');
    final right = norm(attempt) == norm(current.phrase);
    if (right) {
      _guessBonus = InterceptScoring.perGuessedLetter * hiddenLetters.length;
      _award(_guessBonus);
      _revealed.addAll(current.distinctLetters);
      _status = TransmissionStatus.decoded;
      _onTransmissionDecoded();
      _persist();
    } else {
      _loseBar();
    }
    notifyListeners();
    return right;
  }

  /// After a decoded transmission: move on to the next one.
  void advance() {
    if (_status != TransmissionStatus.decoded) return;
    _index++;
    if (campaignComplete) {
      unawaited(
        _progress.unlockAchievement(GameCenterIds.achievementCampaignComplete),
      );
    }
    _resetMessage();
    _persist();
    notifyListeners();
  }

  /// The first transmission ever decoded, right or wrong path — checked
  /// here rather than in [advance] so it fires the moment it happens
  /// (matches the player's real "I just did it" beat), not one screen
  /// later.
  void _onTransmissionDecoded() {
    if (_index == 0) {
      unawaited(
        _progress.unlockAchievement(
          GameCenterIds.achievementFirstTransmission,
        ),
      );
    }
  }

  /// After a lost transmission: try the same one again from scratch. The
  /// points it earned before being lost are kept.
  void retry() {
    _resetMessage();
    notifyListeners();
  }

  /// From the campaign-complete screen: start over, keeping the score.
  void restartCampaign() {
    _index = 0;
    _resetMessage();
    _persist();
    notifyListeners();
  }

  void _loseBar() {
    _bars--;
    if (_bars <= 0) {
      _bars = 0;
      _status = TransmissionStatus.lost;
    }
  }

  /// Adds (or, for Test costs, subtracts) points. Scores never go below 0.
  void _award(int points) {
    _transmissionScore = (_transmissionScore + points).clamp(0, 1 << 30);
    _totalScore = (_totalScore + points).clamp(0, 1 << 30);
  }

  void _resetMessage() {
    _revealed.clear();
    _attempts.clear();
    _bars = InterceptScoring.signalBars;
    _transmissionScore = 0;
    _guessBonus = 0;
    _status = TransmissionStatus.playing;
  }

  /// SharedPreferences updates its in-memory copy synchronously, so a
  /// reload straight after sees these values; the disk write completes in
  /// the background. Also pushes the leaderboard score and cloud save —
  /// fire-and-forget like every [GameCenterProgressService] call, so a
  /// slow or failed network round-trip never delays gameplay.
  void _persist() {
    final prefs = _prefs;
    if (prefs == null) return;
    prefs.setInt(_indexKey, _index);
    prefs.setInt(_scoreKey, _totalScore);
    unawaited(_progress.submitScore(_totalScore));
    unawaited(
      _progress.saveCloudProgress(
        jsonEncode({'index': _index, 'score': _totalScore}),
      ),
    );
  }
}
