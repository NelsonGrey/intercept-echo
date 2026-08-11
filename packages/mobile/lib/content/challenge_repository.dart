import '../domain/operation_type.dart';
import 'challenge.dart';

/// In-memory challenge set for the "Move" and "Preserve" chapters (BRD §8).
///
/// This is a deliberately small vertical slice, not the full MVP content
/// requirement (SRA-BR-005 calls for at least 40 authored challenges across
/// four chapters). It exists to prove the domain engine, content shape, and
/// screens work end to end — replacing this with a real data-driven
/// JSON loader + the other ~32 challenges + CI solver validation
/// (SRA-TR-004) is tracked follow-up work, not something to silently skip.
class ChallengeRepository {
  const ChallengeRepository._();

  static const List<Challenge> all = [
    Challenge(
      id: 'move-01',
      chapter: 'Move',
      title: 'First Shift',
      initialBits: 0x01,
      targetBits: 0x02,
      allowedOperations: [OperationType.shiftLeft],
      moveBudget: 1,
    ),
    Challenge(
      id: 'move-02',
      chapter: 'Move',
      title: 'Three Steps',
      initialBits: 0x01,
      targetBits: 0x08,
      allowedOperations: [OperationType.shiftLeft],
      moveBudget: 3,
    ),
    Challenge(
      id: 'move-03',
      chapter: 'Move',
      title: 'Both Directions',
      initialBits: 0x0F,
      targetBits: 0x3C,
      allowedOperations: [OperationType.shiftLeft, OperationType.shiftRight],
      moveBudget: 3,
    ),
    Challenge(
      id: 'move-04',
      chapter: 'Move',
      title: 'Boundary Loss',
      initialBits: 0xC0,
      targetBits: 0x80,
      allowedOperations: [OperationType.shiftLeft],
      moveBudget: 1,
    ),
    Challenge(
      id: 'preserve-01',
      chapter: 'Preserve',
      title: 'Full Circle',
      initialBits: 0x81,
      targetBits: 0x81,
      allowedOperations: [OperationType.rotateLeft],
      moveBudget: 8,
    ),
    Challenge(
      id: 'preserve-02',
      chapter: 'Preserve',
      title: 'Rotate Into Place',
      initialBits: 0x01,
      targetBits: 0x10,
      allowedOperations: [OperationType.rotateLeft],
      moveBudget: 4,
    ),
    Challenge(
      id: 'transform-01',
      chapter: 'Transform',
      title: 'Keep the High Nibble',
      initialBits: 0xF7,
      targetBits: 0xF0,
      allowedOperations: [OperationType.maskAnd],
      moveBudget: 1,
      maskOperand: 0xF0,
    ),
  ];

  static Challenge byId(String id) => all.firstWhere((c) => c.id == id);
}
