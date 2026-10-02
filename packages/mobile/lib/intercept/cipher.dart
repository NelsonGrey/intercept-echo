/// The letter cipher behind every transmission: each letter is a number
/// from 1 to 26. With [key] 0 it is the plain A=1 … Z=26 alphabet; any
/// other key shifts the alphabet round, so on a keyed transmission the
/// number no longer gives the letter away until the player has worked the
/// key out from letters they have cracked.
class Cipher {
  const Cipher(this.key) : assert(key >= 0 && key < 26);

  final int key;

  static const _a = 65; // 'A'

  /// The number (1–26) that decodes to [letter].
  int codeFor(String letter) {
    final index = letter.codeUnitAt(0) - _a;
    assert(index >= 0 && index < 26, 'not an A–Z letter: $letter');
    return (index + key) % 26 + 1;
  }

  /// The letter that [code] (1–26) decodes to.
  String letterFor(int code) {
    assert(code >= 1 && code <= 26);
    return String.fromCharCode((code - 1 - key) % 26 + _a);
  }
}
