import 'dart:math';

import '../content/challenge.dart';
import '../domain/operation_type.dart';
import '../domain/solver.dart';
import 'transmission.dart';

/// Builds the register puzzle that cracks one letter of a transmission.
///
/// Deterministic: the same transmission, letter and attempt always give
/// the same puzzle (TRD: deterministic fairness), while a retry after a
/// failure (attempt + 1) gives a fresh one.
class PuzzleFactory {
  const PuzzleFactory._();

  static const _shiftOps = [OperationType.shiftLeft, OperationType.shiftRight];

  static Challenge build({
    required int transmissionIndex,
    required Transmission transmission,
    required String letter,
    int attempt = 0,
  }) {
    final target = transmission.cipher.codeFor(letter);
    final letterIndex = transmission.distinctLetters.indexOf(letter);
    final random = Random(
      transmissionIndex * 10007 + letterIndex * 101 + attempt,
    );
    final kind = switch (transmission.kind) {
      PuzzleKind.mixed =>
        letterIndex.isEven ? PuzzleKind.count : PuzzleKind.shift,
      final k => k,
    };
    final id = 't$transmissionIndex-$letter-$attempt';

    if (kind == PuzzleKind.count) {
      // Tutorial messages start from an empty register; later ones start
      // somewhere else, so cells have to be switched off as well as on.
      final start = transmission.key == 0 ? 0 : _nonTarget(random, target, 31);
      final flips = _popCount(start ^ target);
      return Challenge(
        id: id,
        chapter: 'Count',
        title: 'Crack the letter',
        initialBits: start,
        targetBits: target,
        allowedOperations: const [],
        moveBudget: flips + 1,
        targetStyle: TargetStyle.number,
        toggleable: true,
        // Count letters are committed with Submit, never auto-won. Once the
        // tutorial is over, the live value is hidden too (Test reveals it).
        requireSubmit: true,
        hideValue: transmission.key != 0,
        clocked: transmission.clocked,
      );
    }

    // Shift: pick a start whose shortest route to the target is two or
    // three moves, so there is always something to plan. One spare move,
    // since a failure costs a signal bar.
    final candidates = <int, int>{};
    for (var s = 1; s <= 0xFF; s++) {
      if (s == target) continue;
      final d = shortestSolution(
        start: s,
        target: target,
        operations: _shiftOps,
      );
      if (d != null && d >= 2 && d <= 3) candidates[s] = d;
    }
    final starts = candidates.keys.toList()..sort();
    final start = starts[random.nextInt(starts.length)];
    return Challenge(
      id: id,
      chapter: 'Shift',
      title: 'Crack the letter',
      initialBits: start,
      targetBits: target,
      allowedOperations: _shiftOps,
      moveBudget: candidates[start]! + 1,
      targetStyle: TargetStyle.number,
      clocked: transmission.clocked,
    );
  }

  static int _nonTarget(Random random, int target, int max) {
    while (true) {
      final v = random.nextInt(max + 1);
      if (v != target) return v;
    }
  }

  static int _popCount(int v) {
    var n = 0;
    for (var x = v; x != 0; x &= x - 1) {
      n++;
    }
    return n;
  }
}
