import 'package:flutter_test/flutter_test.dart';
import 'package:intercept_echo/content/challenge_repository.dart';
import 'package:intercept_echo/domain/solver.dart';

/// SRA-TR-004: every authored challenge is machine-checked, so content
/// like the old "Full Circle" (which started already solved) cannot ship.
void main() {
  for (final c in ChallengeRepository.all) {
    test('${c.id} "${c.title}" is solvable within its budget', () {
      expect(
        c.initialBits,
        isNot(c.targetBits),
        reason: 'must not start already solved',
      );
      final best = shortestSolution(
        start: c.initialBits,
        target: c.targetBits,
        operations: c.allowedOperations,
        toggles: c.toggleable,
        maskOperand: c.maskOperand,
      );
      expect(best, isNotNull, reason: 'target unreachable');
      expect(best, lessThanOrEqualTo(c.moveBudget));
    });
  }

  test(
    'Shift challenges track par as their shortest solution, with slack '
    'in the budget for PracticeScoring to grade',
    () {
      for (final c in ChallengeRepository.all.where(
        (c) => c.chapter == 'Shift',
      )) {
        final best = shortestSolution(
          start: c.initialBits,
          target: c.targetBits,
          operations: c.allowedOperations,
        );
        expect(c.parMoves, best, reason: c.id);
        expect(
          c.moveBudget,
          c.parMoves! + ChallengeRepository.shiftSlack,
          reason: c.id,
        );
      }
    },
  );

  test('challenge ids and titles are unique', () {
    final ids = ChallengeRepository.all.map((c) => c.id).toSet();
    final titles = ChallengeRepository.all.map((c) => c.title).toSet();
    expect(ids.length, ChallengeRepository.all.length);
    expect(titles.length, ChallengeRepository.all.length);
  });
}
