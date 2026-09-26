import 'cipher.dart';

/// Which register mechanic cracks a transmission's letters.
enum PuzzleKind {
  /// Tap cells until the register equals the letter's number.
  count,

  /// Reach the number with Shift Left (×2) and Shift Right (÷2) only.
  shift,

  /// Alternates count and shift letter by letter.
  mixed,

  /// Reach the number with Shift Left/Right and Rotate Left/Right — Rotate
  /// wraps a bit around instead of losing it, so a route that would spill a
  /// needed bit off the register can wrap it back in instead.
  rotateShift,

  /// Alternates count and rotateShift letter by letter — the escalation
  /// once a player has shown they can shift reliably (see [transmissions]).
  advanced,
}

/// One intercepted message: a short phrase whose letters are cracked by
/// register puzzles. Transmissions run in order; the player never picks
/// one from a list.
class Transmission {
  const Transmission({
    required this.phrase,
    required this.key,
    required this.kind,
    this.clocked = true,
  });

  /// Upper-case A–Z words separated by single spaces.
  final String phrase;

  /// Cipher key: 0 is the tutorial A=1 alphabet; anything else shifts it.
  final int key;

  final PuzzleKind kind;
  final bool clocked;

  Cipher get cipher => Cipher(key);

  List<String> get words => phrase.split(' ');

  /// Each distinct letter once, in first-appearance order. Cracking one
  /// reveals it everywhere it occurs, hangman style.
  List<String> get distinctLetters {
    final seen = <String>{};
    return [
      for (final ch in phrase.split(''))
        if (ch != ' ' && seen.add(ch)) ch,
    ];
  }
}

/// The prototype campaign. Phrases are original to this game
/// (SRA-BR-009). Transmission 4 tells the player the key has changed —
/// from there each message uses its own shifted alphabet. Transmissions
/// 6–8 give three messages of Shift practice inside `mixed` before Rotate
/// is introduced; from transmission 9 on, `advanced` swaps `mixed`'s Shift
/// half for Rotate + Shift, and scores a bonus for using it.
const List<Transmission> transmissions = [
  Transmission(
    phrase: 'SIGNAL FOUND',
    key: 0,
    kind: PuzzleKind.count,
    clocked: false,
  ),
  Transmission(phrase: 'HOLD THE LINE', key: 0, kind: PuzzleKind.count),
  Transmission(phrase: 'SEND MORE POWER', key: 0, kind: PuzzleKind.shift),
  Transmission(phrase: 'KEY HAS CHANGED', key: 3, kind: PuzzleKind.count),
  Transmission(phrase: 'MEET AT DAWN', key: 3, kind: PuzzleKind.shift),
  Transmission(phrase: 'BRING THE MAP', key: 7, kind: PuzzleKind.mixed),
  Transmission(phrase: 'THE TOWER IS DARK', key: 7, kind: PuzzleKind.mixed),
  Transmission(phrase: 'FOLLOW THE RIVER', key: 11, kind: PuzzleKind.mixed),
  Transmission(phrase: 'WAIT FOR MY CALL', key: 11, kind: PuzzleKind.advanced),
  Transmission(phrase: 'CODE BOOK LOST', key: 19, kind: PuzzleKind.advanced),
  Transmission(phrase: 'TRUST NO SIGNAL', key: 19, kind: PuzzleKind.advanced),
  Transmission(
    phrase: 'WE ARE ALMOST HOME',
    key: 23,
    kind: PuzzleKind.advanced,
  ),
];
