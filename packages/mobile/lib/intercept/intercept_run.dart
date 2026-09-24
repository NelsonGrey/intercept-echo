import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../content/challenge.dart';
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
}

/// The player's progress through the Intercept campaign: which
/// transmission they are on, what they have cracked, their signal bars and
/// score. The transmission index and total score persist; the state of a
/// half-decoded message does not (a relaunch restarts that message).
class InterceptRun extends ChangeNotifier {
  InterceptRun({List<Transmission>? campaign})
    : campaign = campaign ?? transmissions;

  final List<Transmission> campaign;

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
    _resetMessage();
    notifyListeners();
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

  void recordCrack(String letter, {required int spareMoves}) {
    if (_status != TransmissionStatus.playing || _revealed.contains(letter)) {
      return;
    }
    _revealed.add(letter);
    _award(
      InterceptScoring.perLetter + InterceptScoring.perSpareMove * spareMoves,
    );
    if (hiddenLetters.isEmpty) _status = TransmissionStatus.decoded;
    _persist();
    notifyListeners();
  }

  /// A failed or abandoned letter puzzle: lose a bar, and the next attempt
  /// at that letter gets a new puzzle.
  void recordFailure(String letter) {
    if (_status != TransmissionStatus.playing) return;
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
    _resetMessage();
    _persist();
    notifyListeners();
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

  void _award(int points) {
    _transmissionScore += points;
    _totalScore += points;
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
  /// the background.
  void _persist() {
    final prefs = _prefs;
    if (prefs == null) return;
    prefs.setInt(_indexKey, _index);
    prefs.setInt(_scoreKey, _totalScore);
  }
}
