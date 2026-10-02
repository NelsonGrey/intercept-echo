import 'package:flutter/material.dart';

import '../theme/game_theme.dart';
import 'transmission.dart';

/// Passed to GameplayScreen when a puzzle cracks one letter of a
/// transmission, so the screen can show the message and the stakes.
class LetterContext {
  const LetterContext({
    required this.transmission,
    required this.revealed,
    required this.letter,
    required this.bars,
  });

  final Transmission transmission;
  final Set<String> revealed;
  final String letter;
  final int bars;

  int get letterNumber => transmission.distinctLetters.indexOf(letter) + 1;
  int get letterTotal => transmission.distinctLetters.length;
}

/// What a letter puzzle hands back to the message board.
class LetterResult {
  const LetterResult({
    required this.cracked,
    this.spareMoves = 0,
    this.pointsSpent = 0,
  });

  const LetterResult.abandoned({int pointsSpent = 0})
    : this(cracked: false, pointsSpent: pointsSpent);

  final bool cracked;
  final int spareMoves;

  /// Points spent on paid Tests during the puzzle.
  final int pointsSpent;
}

/// The intercepted message as hangman slots: cracked letters, blanks, the
/// letter currently being cracked, and (while guessing) typed letters.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.transmission,
    required this.revealed,
    required this.palette,
    this.highlight,
    this.guess = const {},
    this.compact = false,
    this.onTapLetter,
  });

  final Transmission transmission;
  final Set<String> revealed;
  final GameThemePalette palette;

  /// Every slot holding this letter is highlighted.
  final String? highlight;

  /// Typed guesses by slot index (spaces excluded), shown dashed.
  final Map<int, String> guess;
  final bool compact;
  final void Function(String letter)? onTapLetter;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final width = compact ? 20.0 : 30.0;
    final height = compact ? 28.0 : 44.0;
    final font = compact ? 15.0 : 24.0;
    var slot = 0;

    Widget cell(String ch, int index) {
      final shown = revealed.contains(ch);
      final isHighlight = !shown && ch == highlight;
      final typed = shown ? null : guess[index];
      final Color line;
      final String text;
      Color textColor = p.textPrimary;
      if (shown) {
        line = p.textPrimary;
        text = ch;
      } else if (isHighlight) {
        line = p.targetOnBorder;
        text = '?';
        textColor = p.targetOnFg;
      } else if (typed != null) {
        line = p.targetOnBorder;
        text = typed;
        textColor = p.targetOnFg;
      } else {
        line = p.bitOffBorder;
        text = '';
      }
      Widget box = Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: isHighlight
            ? BoxDecoration(
                color: p.targetOnBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: line, width: 2),
              )
            : BoxDecoration(
                border: Border(bottom: BorderSide(color: line, width: 3)),
              ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: font,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      );
      if (!shown && onTapLetter != null) {
        box = Semantics(
          button: true,
          label: 'Hidden letter, tap to crack',
          excludeSemantics: true,
          child: GestureDetector(onTap: () => onTapLetter!(ch), child: box),
        );
      }
      return box;
    }

    return Semantics(
      label: 'Message: ${_spoken()}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final word in transmission.words)
            Padding(
              padding: EdgeInsets.symmetric(vertical: compact ? 3 : 6),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: compact ? 3 : 4,
                children: [for (final ch in word.split('')) cell(ch, slot++)],
              ),
            ),
        ],
      ),
    );
  }

  String _spoken() => transmission.words
      .map(
        (w) => w
            .split('')
            .map((c) => revealed.contains(c) ? c : 'blank')
            .join(' '),
      )
      .join(', ');
}

/// Signal bars: the transmission's lives.
class SignalBars extends StatelessWidget {
  const SignalBars({
    super.key,
    required this.bars,
    required this.palette,
    this.total = 4,
    this.showLabel = true,
    this.alignEnd = true,
  });

  final int bars;
  final int total;
  final GameThemePalette palette;
  final bool showLabel;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Semantics(
      label: 'Signal: $bars of $total bars',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLabel) ...[
            Text(
              'SIGNAL',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: p.overflowLabel,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < total; i++)
                Container(
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
                  width: 8,
                  height: 10.0 + 4 * i,
                  decoration: BoxDecoration(
                    color: i < bars ? p.overflowAccent : null,
                    borderRadius: BorderRadius.circular(2),
                    border: i < bars
                        ? null
                        : Border.all(color: p.overflowAccent, width: 2),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
