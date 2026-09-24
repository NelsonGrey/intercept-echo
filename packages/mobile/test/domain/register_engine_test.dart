import 'package:flutter_test/flutter_test.dart';
import 'package:shift_register_arcade/domain/operation_type.dart';
import 'package:shift_register_arcade/domain/register_engine.dart';
import 'package:shift_register_arcade/domain/register_state.dart';

void main() {
  group('shiftLeft — exhaustive over all 256 values (SRA-TR-002)', () {
    for (var value = 0; value <= 0xFF; value++) {
      test('0x${value.toRadixString(16)}', () {
        final result =
            RegisterEngine.apply(RegisterState(value), OperationType.shiftLeft);
        expect(result.state.bits, (value << 1) & 0xFF);
        expect(result.overflowBit, (value >> 7) & 1);
      });
    }
  });

  group('shiftRight — exhaustive over all 256 values (SRA-TR-002)', () {
    for (var value = 0; value <= 0xFF; value++) {
      test('0x${value.toRadixString(16)}', () {
        final result = RegisterEngine.apply(
            RegisterState(value), OperationType.shiftRight);
        expect(result.state.bits, value >> 1);
        expect(result.overflowBit, value & 1);
      });
    }
  });

  group('mask AND — exhaustive over all 256 values with a fixed operand', () {
    const operand = 0xF0;
    for (var value = 0; value <= 0xFF; value++) {
      test('0x${value.toRadixString(16)} & 0x${operand.toRadixString(16)}',
          () {
        final result = RegisterEngine.apply(
          RegisterState(value),
          OperationType.maskAnd,
          maskOperand: operand,
        );
        expect(result.state.bits, value & operand);
      });
    }
  });

  group('rotate reversibility — property test (TRD §10)', () {
    test('rotateRight undoes rotateLeft for every value', () {
      for (var value = 0; value <= 0xFF; value++) {
        final rotated = RegisterEngine.apply(
            RegisterState(value), OperationType.rotateLeft);
        final restored = RegisterEngine.apply(
            rotated.state, OperationType.rotateRight);
        expect(restored.state.bits, value);
      }
    });

    test('rotateLeft undoes rotateRight for every value', () {
      for (var value = 0; value <= 0xFF; value++) {
        final rotated = RegisterEngine.apply(
            RegisterState(value), OperationType.rotateRight);
        final restored = RegisterEngine.apply(
            rotated.state, OperationType.rotateLeft);
        expect(restored.state.bits, value);
      }
    });

    test('rotate never produces overflow', () {
      for (var value = 0; value <= 0xFF; value++) {
        final left = RegisterEngine.apply(
            RegisterState(value), OperationType.rotateLeft);
        final right = RegisterEngine.apply(
            RegisterState(value), OperationType.rotateRight);
        expect(left.overflowBit, isNull);
        expect(right.overflowBit, isNull);
      }
    });
  });

  group('shift invariants', () {
    test('8 consecutive left shifts always reach zero', () {
      for (var value = 0; value <= 0xFF; value++) {
        var state = RegisterState(value);
        for (var i = 0; i < 8; i++) {
          state = RegisterEngine.apply(state, OperationType.shiftLeft).state;
        }
        expect(state.bits, 0);
      }
    });

    test('8 consecutive right shifts always reach zero', () {
      for (var value = 0; value <= 0xFF; value++) {
        var state = RegisterState(value);
        for (var i = 0; i < 8; i++) {
          state = RegisterEngine.apply(state, OperationType.shiftRight).state;
        }
        expect(state.bits, 0);
      }
    });
  });

  test('operations never produce an out-of-range value', () {
    for (var value = 0; value <= 0xFF; value++) {
      for (final op in OperationType.values) {
        final result = RegisterEngine.apply(RegisterState(value), op,
            maskOperand: 0xAA);
        expect(result.state.bits, inInclusiveRange(0, 0xFF));
      }
    }
  });

  test('toggle flips exactly one bit, for every value and index', () {
    for (var v = 0; v <= 0xFF; v++) {
      for (var i = 0; i < 8; i++) {
        final out = RegisterEngine.toggle(RegisterState(v), i).bits;
        expect(out ^ v, 1 << i);
      }
    }
  });
}
