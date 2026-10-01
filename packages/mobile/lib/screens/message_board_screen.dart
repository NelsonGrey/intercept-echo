import 'package:flutter/material.dart';
import '../shell/shell.dart';

import '../app/app_services.dart';
import '../intercept/intercept_run.dart';
import '../intercept/message_view.dart';
import '../theme/game_theme.dart';
import '../theme/intercept_echo_brand.dart';
import 'gameplay_screen.dart';
import 'guess_screen.dart';
import 'transmission_result_screen.dart';

/// The Intercept hub: the current transmission as hangman blanks. Tap a
/// blank (or "Crack next letter") to open the register puzzle that decodes
/// it, or guess the whole message. A non-gameplay screen, so it carries
/// the banner (SRA-BR-015); the round-exit interstitial fires once per
/// transmission, when it is decoded or lost.
class MessageBoardScreen extends StatefulWidget {
  const MessageBoardScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<MessageBoardScreen> createState() => _MessageBoardScreenState();
}

class _MessageBoardScreenState extends State<MessageBoardScreen> {
  InterceptRun get _run => widget.services.intercept;
  bool _busy = false;

  Future<void> _crack(String letter) async {
    if (_busy || _run.status != TransmissionStatus.playing) return;
    _busy = true;
    final puzzle = _run.puzzleFor(letter);
    final result = await Navigator.of(context).push<LetterResult>(
      MaterialPageRoute(
        builder: (_) => GameplayScreen(
          services: widget.services,
          challenge: puzzle,
          letter: LetterContext(
            transmission: _run.current,
            revealed: _run.revealed,
            letter: letter,
            bars: _run.bars,
          ),
        ),
      ),
    );
    if (result == null || !result.cracked) {
      _run.recordFailure(letter, pointsSpent: result?.pointsSpent ?? 0);
    } else {
      _run.recordCrack(
        letter,
        spareMoves: result.spareMoves,
        pointsSpent: result.pointsSpent,
        difficulty: widget.services.difficulty.value,
        advanced: puzzle.chapter == 'Rotate',
      );
    }
    _busy = false;
    await _afterChange();
  }

  Future<void> _guess() async {
    if (_busy || _run.status != TransmissionStatus.playing) return;
    _busy = true;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => GuessScreen(services: widget.services)),
    );
    _busy = false;
    await _afterChange();
  }

  /// When the transmission ends: one interstitial on the way to the
  /// transmission result screen. The player has already seen how the last
  /// letter or guess went.
  Future<void> _afterChange() async {
    if (!mounted || _run.status == TransmissionStatus.playing) return;
    await widget.services.ads.showInterstitial();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TransmissionResultScreen(services: widget.services),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.services.theme, _run]),
      builder: (context, _) {
        final p = widget.services.theme.palette;
        return Scaffold(
          backgroundColor: p.pageBg,
          body: GameScreenShell(
            adService: widget.services.ads,
            body: EchoBackdrop(
              palette: p,
              intensity: .65,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  child: _run.campaignComplete ? _complete(p) : _board(p),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(GameThemePalette p, String kicker) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Menu',
            icon: Icon(Icons.chevron_left, color: p.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(kicker.toUpperCase(), style: _label(p.textMuted, 12)),
                const SizedBox(height: 2),
                Text(
                  'Intercept',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _board(GameThemePalette p) {
    final run = _run;
    final t = run.current;
    return Column(
      children: [
        _header(p, 'Transmission ${run.index + 1} of ${run.campaign.length}'),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SCORE', style: _label(p.textMuted, 11)),
                  const SizedBox(height: 4),
                  Text(
                    '${run.totalScore}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                ],
              ),
              SignalBars(bars: run.bars, palette: p),
            ],
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: p.bitOffBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.clockTrack, width: 1.5),
                ),
                child: Column(
                  children: [
                    Text('INTERCEPTED MESSAGE', style: _label(p.textMuted, 12)),
                    const SizedBox(height: 14),
                    MessageView(
                      transmission: t,
                      revealed: run.revealed,
                      palette: p,
                      onTapLetter: _crack,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _cipherHint(run),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: p.textMuted,
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
            onPressed: run.nextLetter == null
                ? null
                : () => _crack(run.nextLetter!),
            style: _filled(p),
            child: const Text('Crack next letter'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: _guess,
            style: OutlinedButton.styleFrom(
              foregroundColor: p.textPrimary,
              side: BorderSide(color: p.textPrimary, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Sora',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Guess the message'),
          ),
        ),
      ],
    );
  }

  /// Tells the player what they know about the cipher so far: the plain
  /// alphabet on tutorial messages; on keyed ones, the letters cracked and
  /// the numbers that decoded them — the clues for working out the key.
  String _cipherHint(InterceptRun run) {
    if (run.current.key == 0) {
      return 'Tap a blank to crack it. Cipher: A=1, B=2 … Z=26.';
    }
    final cracked = run.crackedCodes;
    if (cracked.isEmpty) {
      return 'The cipher key has changed. Crack a letter to start working '
          'it out.';
    }
    final pairs = cracked.entries
        .map((e) => '${e.key} = ${e.value}')
        .join(' · ');
    return 'Cracked so far: $pairs';
  }

  Widget _complete(GameThemePalette p) {
    return Column(
      children: [
        _header(p, 'All transmissions'),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Every transmission decoded',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Score ${_run.totalScore}',
                style: TextStyle(fontSize: 18, color: p.textMuted),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: FilledButton(
            onPressed: _run.restartCampaign,
            style: _filled(p),
            child: const Text('Play again'),
          ),
        ),
      ],
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

  TextStyle _label(Color color, double size) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w600,
    letterSpacing: size >= 12 ? 1.2 : 1,
    color: color,
  );
}
