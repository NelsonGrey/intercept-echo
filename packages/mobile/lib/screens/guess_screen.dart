import 'package:flutter/material.dart';
import 'package:game_shell/game_shell.dart';

import '../app/app_services.dart';
import '../intercept/intercept_run.dart';
import '../intercept/message_view.dart';
import '../theme/game_theme.dart';
import '../theme/intercept_echo_brand.dart';

/// Guess the whole message. Typed letters fill the hidden slots in reading
/// order; cracked letters stay fixed. A right guess decodes the
/// transmission with the early-guess bonus; a wrong one costs a signal bar.
/// The outcome shows here first, before the board fires any interstitial.
/// Leaving without submitting costs nothing.
class GuessScreen extends StatefulWidget {
  const GuessScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<GuessScreen> createState() => _GuessScreenState();
}

class _GuessScreenState extends State<GuessScreen> {
  InterceptRun get _run => widget.services.intercept;

  /// Slot indices (spaces excluded) still hidden, in reading order.
  late final List<int> _hiddenSlots;
  late final List<String> _slotLetters;
  final Map<int, String> _typed = {};
  bool? _right;

  static const _rows = ['QWERTYUIOP', 'ASDFGHJKL', 'ZXCVBNM'];

  @override
  void initState() {
    super.initState();
    _slotLetters = _run.current.phrase.replaceAll(' ', '').split('');
    _hiddenSlots = [
      for (var i = 0; i < _slotLetters.length; i++)
        if (!_run.revealed.contains(_slotLetters[i])) i,
    ];
  }

  bool get _full => _hiddenSlots.every(_typed.containsKey);

  void _type(String letter) {
    if (_right != null) return;
    for (final slot in _hiddenSlots) {
      if (!_typed.containsKey(slot)) {
        setState(() => _typed[slot] = letter);
        return;
      }
    }
  }

  void _delete() {
    if (_right != null) return;
    for (final slot in _hiddenSlots.reversed) {
      if (_typed.containsKey(slot)) {
        setState(() => _typed.remove(slot));
        return;
      }
    }
  }

  void _submit() {
    if (!_full || _right != null) return;
    final attempt = [
      for (var i = 0; i < _slotLetters.length; i++)
        _typed[i] ?? _slotLetters[i],
    ].join();
    setState(() => _right = _run.guess(attempt));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.services.theme.palette;
    return Scaffold(
      backgroundColor: p.pageBg,
      body: GameScreenShell(
        adService: widget.services.ads,
        // Deduction in progress: treated like active play, no banner.
        showBanner: false,
        body: EchoBackdrop(
          palette: p,
          intensity: .5,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: Column(
                children: [
                  SizedBox(
                    height: 52,
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Back to the message',
                          icon: Icon(Icons.chevron_left, color: p.textPrimary),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        Expanded(
                          child: Text(
                            'Guess the message',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: p.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
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
                            vertical: 22,
                          ),
                          decoration: BoxDecoration(
                            color: p.bitOffBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: p.clockTrack, width: 1.5),
                          ),
                          child: MessageView(
                            transmission: _run.current,
                            revealed: _run.revealed,
                            guess: _typed,
                            palette: p,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: p.overflowBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              SignalBars(
                                bars: _run.bars,
                                palette: p,
                                showLabel: false,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'A wrong guess costs a signal bar. A right '
                                  'one skips the rest for a bonus.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: p.overflowLabel,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_right == null) _keyboard(p) else _outcome(p, _right!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _keyboard(GameThemePalette p) {
    // Ten keys across the widest row, sized to the screen.
    final keyWidth = (MediaQuery.sizeOf(context).width - 24) / 10 - 5;
    Widget key(String k) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: SizedBox(
        width: keyWidth,
        height: 46,
        child: TextButton(
          onPressed: () => _type(k),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: p.bitOffBg,
            foregroundColor: p.textPrimary,
            side: BorderSide(color: p.bitOffBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Sora',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(k),
        ),
      ),
    );
    return Column(
      children: [
        for (final row in _rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [for (final k in row.split('')) key(k)],
            ),
          ),
        Row(
          children: [
            SizedBox(
              width: 72,
              height: 54,
              child: IconButton.filledTonal(
                tooltip: 'Delete letter',
                onPressed: _delete,
                icon: const Icon(Icons.backspace_outlined),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _full ? _submit : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: p.buttonBg,
                    foregroundColor: p.buttonFg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Submit guess'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _outcome(GameThemePalette p, bool right) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: p.pageBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.bitOffBorder, width: 1.5),
        ),
        child: Column(
          children: [
            Text(
              right ? 'Message decoded!' : 'Not the message',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              right
                  ? 'Early-guess bonus +${_run.guessBonus}'
                  : _run.status == TransmissionStatus.lost
                  ? 'That was your last signal bar.'
                  : 'You lose a signal bar.',
              style: TextStyle(fontSize: 16, color: p.textPrimary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: p.buttonBg,
                  foregroundColor: p.buttonFg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
