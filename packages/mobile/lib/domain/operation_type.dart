/// The register operations the MVP supports (TRD §3.2). Only [maskAnd] is
/// wired up for the mask slot — the TRD calls for choosing one of AND/OR/XOR
/// during discovery; AND is the simplest to teach visually ("keep only
/// these bits"), so it's the one implemented.
enum OperationType { shiftLeft, shiftRight, rotateLeft, rotateRight, maskAnd }

extension OperationTypeLabel on OperationType {
  String get label => switch (this) {
    OperationType.shiftLeft => 'Shift Left',
    OperationType.shiftRight => 'Shift Right',
    OperationType.rotateLeft => 'Rotate Left',
    OperationType.rotateRight => 'Rotate Right',
    OperationType.maskAnd => 'Mask (AND)',
  };

  /// Whether this operation can push a bit out of the register and produce
  /// an overflow resource (BR-003). Rotate wraps the bit back in, so it
  /// never produces overflow; mask never removes a bit position either.
  bool get producesOverflow =>
      this == OperationType.shiftLeft || this == OperationType.shiftRight;
}
