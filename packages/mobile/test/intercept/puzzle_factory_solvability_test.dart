import 'package:flutter_test/flutter_test.dart';
import 'package:shift_register_arcade/domain/solver.dart';
import 'package:shift_register_arcade/intercept/puzzle_factory.dart';
import 'package:shift_register_arcade/intercept/transmission.dart';

/// SRA-TR-004 for Intercept: every letter of every transmission must
/// generate a puzzle that's actually solvable within its move budget, not
/// just plausible-looking. Covers `rotateShift`/`advanced` alongside the
/// original count/shift/mixed kinds, since a BFS candidate search that
/// comes back empty for some target would throw at generation time rather
/// than fail a test — this exercises every letter code 1–26 that any
/// transmission's cipher can produce, not just a couple of examples.
void main() {
  for (var t = 0; t < transmissions.length; t++) {
    final transmission = transmissions[t];
    for (final letter in transmission.distinctLetters) {
      test('transmission $t letter $letter is solvable within its budget', () {
        final puzzle = PuzzleFactory.build(
          transmissionIndex: t,
          transmission: transmission,
          letter: letter,
        );
        expect(
          puzzle.initialBits,
          isNot(puzzle.targetBits),
          reason: 'must not start already solved',
        );
        final best = shortestSolution(
          start: puzzle.initialBits,
          target: puzzle.targetBits,
          operations: puzzle.allowedOperations,
          toggles: puzzle.toggleable,
        );
        expect(best, isNotNull, reason: 'target unreachable');
        expect(best, lessThanOrEqualTo(puzzle.moveBudget));
      });
    }
  }
}
