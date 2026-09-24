import 'package:flutter_test/flutter_test.dart';
import 'package:shift_register_arcade/content/challenge_repository.dart';
import 'package:shift_register_arcade/content/clock.dart';

void main() {
  test('each chapter tightens the tick', () {
    final ticks = ['Move', 'Preserve', 'Transform', 'Overclock']
        .map(tickDurationFor)
        .toList();
    for (var i = 1; i < ticks.length; i++) {
      expect(ticks[i], lessThan(ticks[i - 1]));
    }
  });

  test('only the first two Move challenges are unclocked', () {
    final unclocked = ChallengeRepository.all
        .where((c) => !c.clocked)
        .map((c) => c.id)
        .toList();
    expect(unclocked, ['move-01', 'move-02']);
  });

}
