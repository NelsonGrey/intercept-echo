import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Easy shows each register cell's place value (1, 2, 4 … 128) under the
/// cells; Hard hides it, so the player has to know what each cell is
/// worth. Persisted by name; Easy for new players.
enum Difficulty { easy, hard }

class DifficultySetting extends ValueNotifier<Difficulty> {
  DifficultySetting() : super(Difficulty.easy);

  static const _prefsKey = 'gameplay.difficulty';

  bool get showsPlaceValues => value == Difficulty.easy;

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
