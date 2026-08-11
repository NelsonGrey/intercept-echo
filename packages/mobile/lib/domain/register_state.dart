/// An 8-bit register value. Immutable and always in range — the only way
/// to get a new one is through [RegisterEngine.apply], never direct mutation.
class RegisterState {
  const RegisterState(this.bits) : assert(bits >= 0 && bits <= 0xFF);

  final int bits;

  /// Bit at [index], 0 = least significant.
  bool bitAt(int index) => (bits >> index) & 1 == 1;

  @override
  bool operator ==(Object other) =>
      other is RegisterState && other.bits == bits;

  @override
  int get hashCode => bits.hashCode;

  @override
  String toString() => '0b${bits.toRadixString(2).padLeft(8, '0')}';
}
