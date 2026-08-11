import '../domain/operation_type.dart';

/// One authored challenge (TRD §4: "Authored challenges shall be
/// schema-validated data rather than hard-coded screens"). This is the Dart
/// shape of that schema for now; a real data-driven loader (JSON + CI
/// validation + solver check per SRA-TR-004) is follow-up work — see
/// [ChallengeRepository]'s doc comment.
class Challenge {
  const Challenge({
    required this.id,
    required this.chapter,
    required this.title,
    required this.initialBits,
    required this.targetBits,
    required this.allowedOperations,
    required this.moveBudget,
    this.maskOperand,
  });

  final String id;
  final String chapter;
  final String title;
  final int initialBits;
  final int targetBits;
  final List<OperationType> allowedOperations;

  /// MVP uses a move-count budget rather than a wall-clock timer — simpler
  /// to make deterministic and testable first; the TRD's "visible clock or
  /// deadline" can layer a real timer over this later without touching the
  /// simulation.
  final int moveBudget;

  final int? maskOperand;
}
