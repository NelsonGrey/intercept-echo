import 'dart:collection';

import 'operation_type.dart';
import 'register_engine.dart';
import 'register_state.dart';

/// Shortest-solution search over the 256 register states (TRD SRA-TR-004:
/// every authored challenge must be machine-checked as solvable). Returns
/// the minimum number of moves from [start] to [target] using [operations]
/// and, when [toggles] is true, single-bit toggles — or null if the target
/// is unreachable.
int? shortestSolution({
  required int start,
  required int target,
  required List<OperationType> operations,
  bool toggles = false,
  int? maskOperand,
}) {
  final distance = <int, int>{start: 0};
  final queue = Queue<int>()..add(start);
  while (queue.isNotEmpty) {
    final bits = queue.removeFirst();
    final steps = distance[bits]!;
    if (bits == target) return steps;
    final state = RegisterState(bits);
    final next = <int>[
      for (final op in operations)
        RegisterEngine.apply(state, op, maskOperand: maskOperand).state.bits,
      if (toggles)
        for (var i = 0; i < 8; i++) RegisterEngine.toggle(state, i).bits,
    ];
    for (final n in next) {
      if (!distance.containsKey(n)) {
        distance[n] = steps + 1;
        queue.add(n);
      }
    }
  }
  return null;
}
