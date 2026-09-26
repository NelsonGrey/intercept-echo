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

/// The campaign. Phrases are original to this game (SRA-BR-009).
/// Transmission 4 tells the player the key has changed — from there each
/// message uses its own shifted alphabet. Transmissions 6–8 give three
/// messages of Shift practice inside `mixed` before Rotate is introduced;
/// from transmission 9 on, `advanced` swaps `mixed`'s Shift half for
/// Rotate + Shift, and scores a bonus for using it. `advanced` is the
/// campaign's top difficulty tier — SRA-BR-005's "real difficulty curve"
/// is carried from there by longer phrases and fresh keys, not a new
/// puzzle kind, so transmissions 12+ stay `advanced` through the end of
/// the 50-transmission set.
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
  Transmission(phrase: 'EYES ON THE TARGET', key: 5, kind: PuzzleKind.advanced),
  Transmission(phrase: 'HOLD YOUR POSITION', key: 9, kind: PuzzleKind.advanced),
  Transmission(
    phrase: 'ENEMY CONVOY SPOTTED',
    key: 13,
    kind: PuzzleKind.advanced,
  ),
  Transmission(
    phrase: 'WEATHER IS CLEARING',
    key: 17,
    kind: PuzzleKind.advanced,
  ),
  Transmission(
    phrase: 'AWAITING FURTHER ORDERS',
    key: 21,
    kind: PuzzleKind.advanced,
  ),
  Transmission(
    phrase: 'BRIDGE IS COMPROMISED',
    key: 25,
    kind: PuzzleKind.advanced,
  ),
  Transmission(phrase: 'FALL BACK TO BASE', key: 2, kind: PuzzleKind.advanced),
  Transmission(phrase: 'PACKAGE IS SECURE', key: 6, kind: PuzzleKind.advanced),
  Transmission(
    phrase: 'RADIO SILENCE BROKEN',
    key: 10,
    kind: PuzzleKind.advanced,
  ),
  Transmission(
    phrase: 'NEW COORDINATES SENT',
    key: 14,
    kind: PuzzleKind.advanced,
  ),
  Transmission(
    phrase: 'STORM APPROACHING FAST',
    key: 18,
    kind: PuzzleKind.advanced,
  ),
  Transmission(phrase: 'AGENT WENT DARK', key: 22, kind: PuzzleKind.advanced),
  Transmission(
    phrase: 'SIGNAL IS WEAKENING',
    key: 1,
    kind: PuzzleKind.advanced,
  ),
  Transmission(
    phrase: 'HOLD THIS FREQUENCY',
    key: 4,
    kind: PuzzleKind.advanced,
  ),
  Transmission(
    phrase: 'MISSION IS COMPROMISED',
    key: 8,
    kind: PuzzleKind.advanced,
  ),
  Transmission(
    phrase: 'EXTRACTION POINT READY',
    key: 12,
    kind: PuzzleKind.advanced,
  ),
  Transmission(phrase: 'DO NOT ENGAGE YET', key: 16, kind: PuzzleKind.advanced),
  Transmission(
    phrase: 'BACKUP IS ARRIVING',
    key: 20,
    kind: PuzzleKind.advanced,
  ),
  Transmission(
    phrase: 'THE CIPHER HAS CHANGED',
    key: 24,
    kind: PuzzleKind.advanced,
  ),
  Transmission(
    phrase: 'KEEP THIS CHANNEL OPEN',
    key: 3,
    kind: PuzzleKind.advanced,
  ),
  Transmission(
    phrase: 'NIGHT WATCH BEGINS NOW',
    key: 7,
    kind: PuzzleKind.advanced,
  ),
  Transmission(
    phrase: 'CONTACT LOST AT DAWN',
    key: 11,
    kind: PuzzleKind.advanced,
  ),
  Transmission(phrase: 'THE BRIDGE IS DOWN', key: 15, kind: PuzzleKind.advanced),
  Transmission(
    phrase: 'HOLD THE PERIMETER',
    key: 19,
    kind: PuzzleKind.advanced,
  ),
  Transmission(
    phrase: 'SUPPLIES ARE RUNNING LOW',
    key: 23,
    kind: PuzzleKind.advanced,
  ),
  Transmission(
    phrase: 'THE SAFE HOUSE MOVED',
    key: 2,
    kind: PuzzleKind.advanced,
  ),
  Transmission(
    phrase: 'TRUST THE NEXT VOICE',
    key: 6,
    kind: PuzzleKind.advanced,
  ),
  Transmission(
    phrase: 'DECODE AND STAND BY',
    key: 10,
    kind: PuzzleKind.advanced,
  ),
  Transmission(
    phrase: 'THE BORDER IS CLOSED',
    key: 14,
    kind: PuzzleKind.advanced,
  ),
  Transmission(
    phrase: 'FRIENDLY FORCES NEARBY',
    key: 18,
    kind: PuzzleKind.advanced,
  ),
  Transmission(
    phrase: 'HOSTILE SHIPS SIGHTED',
    key: 22,
    kind: PuzzleKind.advanced,
  ),
  Transmission(
    phrase: 'THE OLD CODE RETURNS',
    key: 1,
    kind: PuzzleKind.advanced,
  ),
  Transmission(phrase: 'KEEP MOVING NORTH', key: 5, kind: PuzzleKind.advanced),
  Transmission(
    phrase: 'THIS IS THE LAST RELAY',
    key: 9,
    kind: PuzzleKind.advanced,
  ),
  Transmission(
    phrase: 'THE NETWORK IS SECURE',
    key: 13,
    kind: PuzzleKind.advanced,
  ),
  Transmission(
    phrase: 'ONE FINAL TRANSMISSION',
    key: 17,
    kind: PuzzleKind.advanced,
  ),
  Transmission(
    phrase: 'YOU ARE NOW COMMAND',
    key: 21,
    kind: PuzzleKind.advanced,
  ),
  Transmission(
    phrase: 'SIGNAL COMPLETE OUT',
    key: 25,
    kind: PuzzleKind.advanced,
  ),
];
