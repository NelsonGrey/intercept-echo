import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Easy shows every register cell's place value (1, 2, 4 … 128) under the
/// cells; Normal shows a handful, different ones each round, so partial
/// knowledge never settles into a fixed cheat sheet; Hard shows none, so
/// the player has to know what every cell is worth. Persisted by name;
/// Easy for new players.
enum Difficulty { easy, normal, hard }

class DifficultySetting extends ValueNotifier<Difficulty> {
  DifficultySetting() : super(Difficulty.easy);

  static const _prefsKey = 'gameplay.difficulty';

  /// How many of Normal's eight place values are shown for a given puzzle.
  static const _normalMinShown = 3;
  static const _normalMaxShown = 5;

  static const _allBitIndices = {0, 1, 2, 3, 4, 5, 6, 7};

  /// Which of the register's eight place values (bit index 7 = 128 down to
  /// bit index 0 = 1) are shown under the cells for [challengeId] at this
  /// difficulty. Deterministic per puzzle — the same puzzle always reveals
  /// the same cells, so a relaunch mid-round doesn't hand the player a
  /// different hint — but different puzzles reveal different ones.
  Set<int> visiblePlaceValues(String challengeId) {
    switch (value) {
      case Difficulty.easy:
        return _allBitIndices;
      case Difficulty.hard:
        return const {};
      case Difficulty.normal:
        final random = Random(_stableHash(challengeId));
        final count =
            _normalMinShown +
            random.nextInt(_normalMaxShown - _normalMinShown + 1);
        final indices = _allBitIndices.toList()..shuffle(random);
        return indices.take(count).toSet();
    }
  }

  /// A hash that's stable across app runs and platforms, unlike
  /// [String.hashCode] (its algorithm isn't part of Dart's spec).
  static int _stableHash(String s) {
    var hash = 0;
    for (final unit in s.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    value = Difficulty.values.firstWhere(
      (d) => d.name == saved,
      orElse: () => Difficulty.easy,
    );
  }

  Future<void> set(Difficulty difficulty) async {
    value = difficulty;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, difficulty.name);
  }
}
