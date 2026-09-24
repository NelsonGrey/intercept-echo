import 'package:flutter/material.dart';
import 'package:game_shell/game_shell.dart';

import '../app/app_services.dart';
import '../intercept/intercept_run.dart';
import '../intercept/message_view.dart';
import '../theme/game_theme.dart';
import 'message_board_screen.dart';

/// End of a transmission, decoded or lost. Reached after the round-exit
/// interstitial; carries the banner like every non-gameplay screen. Next
/// (or Try again) goes straight back to the message board — no ad gates
/// the start of the next transmission.
class TransmissionResultScreen extends StatelessWidget {
  const TransmissionResultScreen({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final run = services.intercept;
    final p = services.theme.palette;
    final decoded = run.status == TransmissionStatus.decoded;
    final t = run.current;
    final guessed = run.guessBonus ~/ InterceptScoring.perGuessedLetter;
    final cracked = decoded
        ? t.distinctLetters.length - guessed
        : run.revealed.length;

    void goBoard() => Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MessageBoardScreen(services: services)),
    );

    Widget stat(String label, Widget value) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: p.bitOffBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: p.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          value,
        ],
      ),
    );
    Text big(String s) => Text(
      s,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: p.textPrimary,
      ),
    );

    return Scaffold(
      backgroundColor: p.pageBg,
      body: GameScreenShell(
        adService: services.ads,
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'TRANSMISSION ${run.index + 1} OF ${run.campaign.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: p.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        decoded
                            ? (guessed > 0
                                  ? 'Decoded: guessed early!'
                                  : 'Transmission decoded')
                            : 'Signal lost',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        decoration: BoxDecoration(
                          color: p.bitOffBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: p.clockTrack, width: 1.5),
                        ),
                        child: MessageView(
                          transmission: t,
                          revealed: run.revealed,
                          palette: p,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Rows that size to their content: a fixed grid cell
                      // clips when a label wraps at larger text sizes.
                      for (final pair in [
                        [
                          stat(
                            'Letters cracked',
                            big('$cracked of ${t.distinctLetters.length}'),
                          ),
                          stat('Early-guess bonus', big('+${run.guessBonus}')),
                        ],
                        [
                          stat(
                            'Signal left',
                            SignalBars(
                              bars: run.bars,
                              palette: p,
                              showLabel: false,
                              alignEnd: false,
                            ),
                          ),
                          stat('Score', big('${run.totalScore}')),
                        ],
                      ])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: pair[0]),
                                const SizedBox(width: 10),
                                Expanded(child: pair[1]),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: FilledButton(
                    onPressed: () {
                      decoded ? run.advance() : run.retry();
                      goBoard();
                    },
                    style: _filled(p),
                    child: Text(decoded ? 'Next transmission' : 'Try again'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      // Leave the finished transmission settled for next
                      // time: decoded moves on, lost starts over.
                      decoded ? run.advance() : run.retry();
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.textPrimary,
                      side: BorderSide(color: p.textPrimary, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Menu'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _filled(GameThemePalette p) => FilledButton.styleFrom(
    backgroundColor: p.buttonBg,
    foregroundColor: p.buttonFg,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    textStyle: const TextStyle(
      fontFamily: 'Sora',
      fontSize: 17,
      fontWeight: FontWeight.w600,
    ),
  );
}
