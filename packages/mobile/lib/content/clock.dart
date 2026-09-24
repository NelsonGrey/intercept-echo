/// The round clock (BRD §6: "a visible clock or deadline"). A round gets one
/// cycle of [ticksPerCycle] ticks — one per register bit — and fails when
/// the cycle completes before the target is matched. The clock sits on top
/// of the move budget; both limits apply.
const int ticksPerCycle = 8;

/// Tick length by chapter: each chapter tightens the clock a little
/// (BRD §8's Overclock is "shorter cycles"). Unknown chapters get a
/// middle-of-the-road 1s.
Duration tickDurationFor(String chapter) => switch (chapter) {
      'Count' || 'Shift' => const Duration(milliseconds: 1500),
      'Preserve' => const Duration(milliseconds: 1250),
      'Transform' => const Duration(milliseconds: 1000),
      'Overclock' => const Duration(milliseconds: 750),
      _ => const Duration(milliseconds: 1000),
    };

/// The "Relaxed clock" accessibility setting doubles every tick (TRD
/// SRA-TR-008). Accessibility features are never monetized (BRD §9).
const int relaxedClockMultiplier = 2;
