import '../domain/operation_type.dart';
import 'clock.dart';

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
    this.clocked = true,
  });

  final String id;
  final String chapter;
  final String title;
  final int initialBits;
  final int targetBits;
  final List<OperationType> allowedOperations;

  /// Moves allowed. The round clock ([clocked], lib/content/clock.dart)
  /// runs alongside this in the screen layer; the simulation itself stays
  /// timer-free and deterministic.
  final int moveBudget;

  final int? maskOperand;

  /// Whether the round clock runs. Off only for the opening challenges, so
  /// players learn to shift before they learn to hurry.
  final bool clocked;

  Duration get tickDuration => tickDurationFor(chapter);
}
