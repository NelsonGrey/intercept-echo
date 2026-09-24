import '../domain/operation_type.dart';
import 'clock.dart';

/// One authored challenge (TRD §4: "Authored challenges shall be
/// schema-validated data rather than hard-coded screens"). This is the Dart
/// shape of that schema for now; a real data-driven loader (JSON + CI
/// validation + solver check per SRA-TR-004) is follow-up work — see
/// [ChallengeRepository]'s doc comment.
/// How the target is shown: as a bit pattern to copy, or as a number the
/// register must equal.
enum TargetStyle { bits, number }

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
    this.targetStyle = TargetStyle.bits,
    this.toggleable = false,
    this.requireSubmit = false,
    this.hideValue = false,
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

  final TargetStyle targetStyle;

  /// Whether tapping a register cell flips it. Toggle challenges also show
  /// each cell's place value (128…1) so players learn what cells are worth.
  final bool toggleable;

  /// The round does not win on its own when the register matches: the
  /// player must press Submit. A wrong Submit costs a move.
  final bool requireSubmit;

  /// The live decimal readout is hidden; the player works out the value
  /// from the bits, or spends a Test to see it.
  final bool hideValue;

  Duration get tickDuration => tickDurationFor(chapter);
}
