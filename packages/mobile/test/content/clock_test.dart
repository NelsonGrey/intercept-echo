import 'package:flutter_test/flutter_test.dart';
import 'package:intercept_echo/content/challenge_repository.dart';
import 'package:intercept_echo/content/clock.dart';

void main() {
  test('each chapter tightens the tick', () {
    final ticks = [
      'Shift',
      'Preserve',
      'Transform',
      'Overclock',
    ].map(tickDurationFor).toList();
    for (var i = 1; i < ticks.length; i++) {
      expect(ticks[i], lessThan(ticks[i - 1]));
    }
  });

  test('only the opening challenges of each new mechanic are unclocked', () {
    final unclocked = ChallengeRepository.all
        .where((c) => !c.clocked)
        .map((c) => c.id)
        .toList();
    expect(unclocked, ['count-01', 'count-02', 'count-03', 'shift-01']);
  });
}
