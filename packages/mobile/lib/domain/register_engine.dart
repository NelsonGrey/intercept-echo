import 'operation_type.dart';
import 'register_state.dart';

/// The result of applying one [OperationType] to a [RegisterState]:
/// TRD §3.2 requires every operation to "specify outgoing bits, inserted
/// bits, overflow rewards" — [overflowBit] is exactly that, non-null only
/// for the two shift operations.
class OperationResult {
  const OperationResult(this.state, {this.overflowBit});

  final RegisterState state;
  final int? overflowBit;
}

/// Pure, deterministic register operations (TRD §3.2). No timing, no
/// randomness, no I/O — every method is a total function of its inputs, so
/// the whole engine is exhaustively testable over all 256 byte values (see
/// test/domain/register_engine_test.dart).
class RegisterEngine {
  const RegisterEngine._();

  static OperationResult apply(
    RegisterState state,
    OperationType op, {
    int? maskOperand,
  }) {
    switch (op) {
      case OperationType.shiftLeft:
        final outgoing = (state.bits >> 7) & 1;
        final next = (state.bits << 1) & 0xFF;
        return OperationResult(RegisterState(next), overflowBit: outgoing);

      case OperationType.shiftRight:
        final outgoing = state.bits & 1;
        final next = (state.bits >> 1) & 0xFF;
        return OperationResult(RegisterState(next), overflowBit: outgoing);

      case OperationType.rotateLeft:
        final outgoing = (state.bits >> 7) & 1;
        final next = ((state.bits << 1) | outgoing) & 0xFF;
        return OperationResult(RegisterState(next));

      case OperationType.rotateRight:
        final outgoing = state.bits & 1;
        final next = ((state.bits >> 1) | (outgoing << 7)) & 0xFF;
        return OperationResult(RegisterState(next));

      case OperationType.maskAnd:
        final operand = maskOperand ?? 0xFF;
        return OperationResult(RegisterState(state.bits & operand));
    }
  }

  /// Flips the bit at [index] (0 = least significant). The Count chapter's
  /// only move: tap a cell to switch it between 0 and 1.
  static RegisterState toggle(RegisterState state, int index) {
    assert(index >= 0 && index < 8);
    return RegisterState(state.bits ^ (1 << index));
  }
}
