import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intercept_echo/intercept/cipher.dart';
import 'package:intercept_echo/intercept/intercept_run.dart';
import 'package:intercept_echo/intercept/puzzle_factory.dart';
import 'package:intercept_echo/intercept/transmission.dart';
import 'package:intercept_echo/domain/solver.dart';
import 'package:intercept_echo/settings/difficulty_setting.dart';

void main() {
  group('Cipher', () {
    test('key 0 is A=1 … Z=26', () {
      const c = Cipher(0);
      expect(c.codeFor('A'), 1);
      expect(c.codeFor('G'), 7);
      expect(c.codeFor('Z'), 26);
    });

    test('every key round-trips every letter within 1–26', () {
      for (var key = 0; key < 26; key++) {
        final c = Cipher(key);
        final codes = <int>{};
        for (var i = 0; i < 26; i++) {
          final letter = String.fromCharCode(65 + i);
          final code = c.codeFor(letter);
          expect(code, inInclusiveRange(1, 26));
          expect(c.letterFor(code), letter);
          codes.add(code);
        }
        expect(codes.length, 26, reason: 'key $key must be a permutation');
      }
    });
  });

  group('Transmissions', () {
    test('phrases are upper-case words with single spaces', () {
      for (final t in transmissions) {
        expect(
          t.phrase,
          matches(RegExp(r'^[A-Z]+( [A-Z]+)*$')),
          reason: t.phrase,
        );
      }
    });

    test('the first three use the tutorial cipher, then keys change', () {
      expect(transmissions.take(3).every((t) => t.key == 0), isTrue);
      expect(transmissions.skip(3).every((t) => t.key != 0), isTrue);
    });

    // SRA-TR-004: every letter of every transmission, on first and retry
    // attempts, produces a puzzle the solver can finish within budget.
    for (var i = 0; i < transmissions.length; i++) {
      final t = transmissions[i];
      test('every puzzle in "${t.phrase}" is solvable within budget', () {
        for (final letter in t.distinctLetters) {
          for (var attempt = 0; attempt < 3; attempt++) {
            final c = PuzzleFactory.build(
              transmissionIndex: i,
              transmission: t,
              letter: letter,
              attempt: attempt,
            );
            expect(c.targetBits, t.cipher.codeFor(letter));
            expect(c.initialBits, isNot(c.targetBits));
            final best = shortestSolution(
              start: c.initialBits,
              target: c.targetBits,
              operations: c.allowedOperations,
              toggles: c.toggleable,
            );
            expect(best, isNotNull, reason: '$letter attempt $attempt');
            expect(best, lessThanOrEqualTo(c.moveBudget));
          }
        }
      });
    }

    test('puzzles are deterministic, and a retry is a new puzzle', () {
      final t = transmissions[4];
      Map<String, int> shape(int attempt) {
        final c = PuzzleFactory.build(
          transmissionIndex: 4,
          transmission: t,
          letter: 'M',
          attempt: attempt,
        );
        return {'start': c.initialBits, 'budget': c.moveBudget};
      }

      expect(shape(0), shape(0));
      final starts = {
        for (final a in [0, 1, 2]) shape(a)['start'],
      };
      expect(starts.length, greaterThan(1));
    });
  });

  group('InterceptRun', () {
    late InterceptRun run;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      run = InterceptRun();
      await run.load();
    });

    test('cracking a letter reveals it everywhere and scores', () {
      // SIGNAL FOUND: N appears twice.
      run.recordCrack('N', spareMoves: 2);
      expect(run.revealed, {'N'});
      expect(run.hiddenLetters, isNot(contains('N')));
      expect(run.totalScore, 100 + 2 * 20);
    });

    test('Hard mode scores cracked letters x1.5, costs after', () {
      // (100 + 20) x 1.5 = 180, minus a 1-point Test.
      run.recordCrack(
        'S',
        spareMoves: 1,
        pointsSpent: 1,
        difficulty: Difficulty.hard,
      );
      expect(run.totalScore, 179);
    });

    test('Normal mode scores cracked letters x1.25', () {
      // 100 x 1.25 = 125.
      run.recordCrack('S', spareMoves: 0, difficulty: Difficulty.normal);
      expect(run.totalScore, 125);
    });

    test('the early-guess bonus is not multiplied', () {
      run.recordCrack('S', spareMoves: 0, difficulty: Difficulty.hard);
      final before = run.totalScore;
      final hidden = run.hiddenLetters.length;
      run.guess('SIGNAL FOUND');
      expect(run.totalScore - before, 150 * hidden);
    });

    test('Test costs come off the score, never below zero', () {
      run.recordCrack('S', spareMoves: 0, pointsSpent: 3);
      expect(run.totalScore, 97);
      run.recordFailure('I', pointsSpent: 500);
      expect(run.totalScore, 0);
    });

    test('failures cost bars and the fourth loses the transmission', () {
      for (var i = 0; i < 3; i++) {
        run.recordFailure('S');
      }
      expect(run.bars, 1);
      expect(run.status, TransmissionStatus.playing);
      run.recordFailure('S');
      expect(run.status, TransmissionStatus.lost);
    });

    test('a failed letter gets a new puzzle next time', () {
      final first = run.puzzleFor('S').id;
      run.recordFailure('S');
      expect(run.puzzleFor('S').id, isNot(first));
    });

    test('a right guess decodes with a bonus per hidden letter', () {
      run.recordCrack('S', spareMoves: 0);
      final hidden = run.hiddenLetters.length;
      expect(run.guess('signal found'), isTrue);
      expect(run.status, TransmissionStatus.decoded);
      expect(run.guessBonus, 150 * hidden);
    });

    test('a wrong guess costs a bar', () {
      expect(run.guess('SIGNAL LOST'), isFalse);
      expect(run.bars, 3);
      expect(run.status, TransmissionStatus.playing);
    });

    test('cracking every letter decodes; advance persists progress', () async {
      for (final l in run.current.distinctLetters) {
        run.recordCrack(l, spareMoves: 0);
      }
      expect(run.status, TransmissionStatus.decoded);
      run.advance();
      expect(run.index, 1);
      expect(run.bars, 4);
      expect(run.revealed, isEmpty);

      final reloaded = InterceptRun();
      await reloaded.load();
      expect(reloaded.index, 1);
      expect(reloaded.totalScore, run.totalScore);
    });

    test('retry after a loss restarts the same transmission', () {
      for (var i = 0; i < 4; i++) {
        run.recordFailure('S');
      }
      run.retry();
      expect(run.index, 0);
      expect(run.bars, 4);
      expect(run.status, TransmissionStatus.playing);
    });
  });
}
