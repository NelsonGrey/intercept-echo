import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:game_shell/game_shell.dart';

import '../app/app_services.dart';
import '../content/challenge.dart';
import '../content/challenge_repository.dart';
import '../content/clock.dart';
import '../domain/operation_type.dart';
import '../domain/register_engine.dart';
import '../domain/register_state.dart';
import '../gamecenter/game_center_progress_service.dart';
import '../intercept/intercept_run.dart';
import '../intercept/message_view.dart';
import '../theme/game_theme.dart';
import '../theme/intercept_echo_brand.dart';
import 'results_screen.dart';

/// The one gameplay screen in this vertical slice, laid out per the "Final
/// HUD" artboard of the Shift-Register HUD design canvas and colored from
/// the player's [GameThemePalette].
///
/// Clocked challenges run one cycle of [ticksPerCycle] ticks, shown by the
/// ring; the cycle stops while paused, and running out fails the round
/// just as running out of moves does. Unclocked challenges show moves
/// remaining in the ring instead.
///
/// Ad placement follows the portfolio rule (see game-shell's README "Ad
/// placement policy"): the banner is hidden while [_isPaused] is false
/// (active target resolution) and shown the instant the player pauses —
/// same route, dynamically toggled `showBanner`, not two separate screens.
/// The interstitial is fired once, right before navigating to
/// [ResultsScreen] on win or fail — never before the round starts.
class GameplayScreen extends StatefulWidget {
  const GameplayScreen({
    super.key,
    required this.services,
    required this.challenge,
    this.letter,
  });

  final AppServices services;
  final Challenge challenge;

  /// Set when this puzzle cracks a letter of an Intercept transmission: the
  /// screen then shows the message and signal bars, and on Continue pops
  /// back to the message board with a [LetterResult] — the board owns the
  /// transmission's round-exit interstitial, not each letter.
  final LetterContext? letter;

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  late RegisterState _current;
  late int _movesRemaining;
  bool _isPaused = false;
  bool _resolved = false;

  /// Set when the round ends; drives the in-place result card. The
  /// interstitial waits until the player taps Continue, so they always see
  /// how the round went first.
  _Outcome? _outcome;
  bool _leaving = false;

  /// 1-bits pushed off either end (BR-003's overflow resource). Counted and
  /// shown, but not yet spendable — the Overclock chapter adds that.
  int _overflowCharge = 0;

  /// Tests used this puzzle; the first is free, later ones cost points.
  int _testsUsed = 0;
  int _pointsSpent = 0;

  /// The register value at the last Test, shown until the register changes.
  int? _testedBits;

  /// Brief feedback after a wrong Submit.
  String? _submitNote;

  /// The last bit that spilled out of each end, or null before any spill.
  int? _lastSpillLeft;
  int? _lastSpillRight;

  static const _overflowPips = 4;

  /// Ticks left in the cycle, or null for an unclocked challenge.
  int? _ticksRemaining;
  Timer? _clock;

  /// Which place values (bit index 7 = 128 … 0 = 1) are shown under the
  /// cells this round. Fixed for the round's lifetime — computed once here
  /// rather than in a getter — so a mid-round rebuild (pausing, a wrong
  /// Submit) can't reshuffle Normal's partial reveal out from under the
  /// player.
  late final Set<int> _visiblePlaceValues;

  @override
  void initState() {
    super.initState();
    _current = RegisterState(widget.challenge.initialBits);
    _movesRemaining = widget.challenge.moveBudget;
    _visiblePlaceValues = _numberMode
        ? widget.services.difficulty.visiblePlaceValues(widget.challenge.id)
        : const {};
    widget.services.ads.preloadInterstitial();
    if (widget.challenge.clocked) {
      _ticksRemaining = ticksPerCycle;
      _startClock();
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  /// Starts (or, after a pause, restarts) the tick timer. A tick in
  /// progress when the player paused starts over on resume.
  void _startClock() {
    final multiplier = widget.services.relaxedClock.value
        ? relaxedClockMultiplier
        : 1;
    _clock?.cancel();
    _clock = Timer.periodic(
      widget.challenge.tickDuration * multiplier,
      (_) => _onTick(),
    );
  }

  void _onTick() {
    if (_resolved || _isPaused || _ticksRemaining == null) return;
    setState(() => _ticksRemaining = _ticksRemaining! - 1);
    if (_ticksRemaining! <= 0) {
      _finish(won: false, timedOut: true);
    }
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
    if (_ticksRemaining == null || _resolved) return;
    if (_isPaused) {
      _clock?.cancel();
    } else {
      _startClock();
    }
  }

  bool get _numberMode => widget.challenge.targetStyle == TargetStyle.number;

  /// Count chapter: tapping a cell flips it and costs one move.
  void _toggle(int index) {
    if (_resolved || _isPaused || !widget.challenge.toggleable) return;
    // With Submit, the last move can be spent and still submitted; toggling
    // stops once the moves run out.
    if (widget.challenge.requireSubmit && _movesRemaining <= 0) return;
    setState(() {
      _current = RegisterEngine.toggle(_current, index);
      _movesRemaining--;
      _submitNote = null;
    });
    if (!widget.challenge.requireSubmit) _checkResolution();
  }

  int get _nextTestCost => _testsUsed == 0 ? 0 : InterceptScoring.testCost;

  /// Reveals the register's current value. Free the first time, then
  /// [InterceptScoring.testCost] points each.
  void _test() {
    if (_resolved || _isPaused) return;
    setState(() {
      _pointsSpent += _nextTestCost;
      _testsUsed++;
      _testedBits = _current.bits;
    });
  }

  /// Commits the answer. Right wins; wrong costs a move, and with none
  /// left the round is lost.
  void _submit() {
    if (_resolved || _isPaused) return;
    if (_current.bits == widget.challenge.targetBits) {
      _finish(won: true);
      return;
    }
    if (_movesRemaining <= 0) {
      _finish(won: false);
      return;
    }
    setState(() {
      _movesRemaining--;
      _submitNote = "That's not it. −1 move";
    });
  }

  /// What the VALUE readout shows: the live value, or when hidden, the
  /// last Test's result while the register still holds it.
  String get _valueText {
    if (!widget.challenge.hideValue) return '${_current.bits}';
    return _testedBits == _current.bits ? '$_testedBits' : '?';
  }

  void _applyOperation(OperationType op) {
    if (_resolved || _isPaused) return;
    final result = RegisterEngine.apply(
      _current,
      op,
      maskOperand: widget.challenge.maskOperand,
    );
    setState(() {
      _current = result.state;
      _movesRemaining--;
      final spilled = result.overflowBit;
      if (spilled != null) {
        _overflowCharge += spilled;
        if (op == OperationType.shiftLeft) {
          _lastSpillLeft = spilled;
        } else {
          _lastSpillRight = spilled;
        }
      }
    });
    _checkResolution();
  }

  /// A horizontal swipe on the register runs the shift (or, in rotate-only
  /// challenges, the rotate) in that direction, when the challenge allows it.
  void _onSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 200) return;
    final allowed = widget.challenge.allowedOperations;
    final candidates = velocity < 0
        ? [OperationType.shiftLeft, OperationType.rotateLeft]
        : [OperationType.shiftRight, OperationType.rotateRight];
    for (final op in candidates) {
      if (allowed.contains(op)) {
        _applyOperation(op);
        return;
      }
    }
  }

  bool get _hasSwipe => widget.challenge.allowedOperations.any(
    (op) =>
        op == OperationType.shiftLeft ||
        op == OperationType.shiftRight ||
        op == OperationType.rotateLeft ||
        op == OperationType.rotateRight,
  );

  void _checkResolution() {
    final target = widget.challenge.targetBits;
    if (_current.bits == target) {
      _finish(won: true);
    } else if (_movesRemaining <= 0) {
      _finish(won: false);
    }
  }

  void _finish({required bool won, bool timedOut = false}) {
    if (_resolved) return;
    _resolved = true;
    _clock?.cancel();
    if (won && widget.letter == null) {
      final movesUsed = widget.challenge.moveBudget - _movesRemaining;
      if (PracticeScoring.scoreFor(widget.challenge, movesUsed) ==
          PracticeScoring.perfectScore) {
        unawaited(
          widget.services.progress.unlockAchievement(
            GameCenterIds.achievementPerfectShift,
          ),
        );
      }
    }
    setState(() => _outcome = _Outcome(won: won, timedOut: timedOut));
  }

  /// Leaves the finished round. Round-exit: exactly one interstitial, on
  /// the way to a non-gameplay screen, after the player has seen the
  /// result — never gating a round's start.
  Future<void> _continue() async {
    final outcome = _outcome;
    if (outcome == null || _leaving) return;
    _leaving = true;
    if (widget.letter != null) {
      Navigator.of(context).pop(
        LetterResult(
          cracked: outcome.won,
          spareMoves: _movesRemaining,
          pointsSpent: _pointsSpent,
        ),
      );
      return;
    }
    await widget.services.ads.showInterstitial();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          services: widget.services,
          challenge: widget.challenge,
          won: outcome.won,
          movesUsed: widget.challenge.moveBudget - _movesRemaining,
          timedOut: outcome.timedOut,
        ),
      ),
    );
  }

  /// "Move · 3 of 4": this challenge's position within its chapter.
  String get _chapterPosition {
    final inChapter = ChallengeRepository.all
        .where((c) => c.chapter == widget.challenge.chapter)
        .toList();
    final index = inChapter.indexWhere((c) => c.id == widget.challenge.id);
    return '${widget.challenge.chapter} · ${index + 1} of ${inChapter.length}';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GameThemeId>(
      valueListenable: widget.services.theme,
      builder: (context, id, _) {
        final p = gameThemePalettes[id]!;
        final scaffold = Scaffold(
          backgroundColor: p.pageBg,
          body: GameScreenShell(
            adService: widget.services.ads,
            // Dynamic per the ad-placement rule: banner appears the instant
            // the player pauses, disappears the instant they resume.
            showBanner: _isPaused,
            // GameScreenShell already applies the top inset around its
            // banner slot, so only the bottom one is added here.
            body: EchoBackdrop(
              palette: p,
              intensity: .45,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  child: Column(
                    children: [
                      _header(p),
                      if (widget.letter != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: MessageView(
                            transmission: widget.letter!.transmission,
                            revealed: _outcome?.won == true
                                ? {
                                    ...widget.letter!.revealed,
                                    widget.letter!.letter,
                                  }
                                : widget.letter!.revealed,
                            highlight: widget.letter!.letter,
                            palette: p,
                            compact: true,
                          ),
                        ),
                      Expanded(
                        child: _isPaused
                            ? Center(
                                child: Text(
                                  'Paused',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: p.textPrimary,
                                  ),
                                ),
                              )
                            : Stack(
                                children: [
                                  _board(p),
                                  if (_outcome != null)
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: _resultCard(p, _outcome!),
                                    ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        if (widget.letter == null) return scaffold;
        // Intercept commit rule: leaving an unfinished letter forfeits it.
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _leaveLetter();
          },
          child: scaffold,
        );
      },
    );
  }

  Future<void> _leaveLetter() async {
    if (_resolved) {
      _continue();
      return;
    }
    final wasPaused = _isPaused;
    if (!wasPaused) _togglePause();
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave this letter?'),
        content: const Text('Leaving before you crack it costs a signal bar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (leave == true) {
      _resolved = true;
      _clock?.cancel();
      Navigator.of(
        context,
      ).pop(LetterResult.abandoned(pointsSpent: _pointsSpent));
    } else if (!wasPaused) {
      _togglePause();
    }
  }

  Widget _resultCard(GameThemePalette p, _Outcome outcome) {
    final c = widget.challenge;
    final target = c.targetBits;
    final value = _current.bits;
    final letter = widget.letter;
    final title = letter != null && outcome.won
        ? 'Letter cracked'
        : outcome.won
        ? 'Target Matched'
        : (outcome.timedOut ? 'Out of Time' : 'Out of Moves');
    final String detail;
    if (letter != null) {
      detail = outcome.won
          ? '$target = ${letter.letter}'
          : 'The letter stays hidden. You lose a signal bar.';
    } else if (c.targetStyle == TargetStyle.number) {
      detail = outcome.won
          ? 'You made $target.'
          : 'The register is $value. The target was $target.';
    } else {
      final matching = List.generate(
        8,
        (i) => _current.bitAt(i) == (((target >> i) & 1) == 1),
      ).where((m) => m).length;
      detail = outcome.won
          ? 'Pattern matched.'
          : '$matching of 8 bits matched the target.';
    }
    final used = c.moveBudget - _movesRemaining;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: p.pageBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.bitOffBorder, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  outcome.won
                      ? Icons.check_circle
                      : (outcome.timedOut ? Icons.timer_off : Icons.block),
                  color: outcome.won ? p.matchHit : p.matchMiss,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: p.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              '$used of ${c.moveBudget} moves used',
              style: TextStyle(fontSize: 14, color: p.textMuted),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _continue,
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
                child: Text(
                  widget.letter != null ? 'Back to the message' : 'Continue',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(GameThemePalette p) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          IconButton(
            tooltip: widget.letter != null
                ? 'Back to the message'
                : 'Back to challenges',
            icon: Icon(Icons.chevron_left, color: p.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  (widget.letter != null
                          ? 'Letter ${widget.letter!.letterNumber} of '
                                '${widget.letter!.letterTotal}'
                          : _chapterPosition)
                      .toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _label(p.textMuted, size: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.challenge.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (_resolved)
            // Nothing to pause once the round is over.
            const SizedBox(width: 48)
          else
            IconButton(
              tooltip: _isPaused ? 'Resume' : 'Pause',
              icon: Icon(
                _isPaused ? Icons.play_arrow : Icons.pause,
                color: p.textPrimary,
              ),
              onPressed: _togglePause,
            ),
        ],
      ),
    );
  }

  Widget _board(GameThemePalette p) {
    final target = widget.challenge.targetBits;
    final matches = List.generate(
      8,
      (i) => _current.bitAt(7 - i) == (((target >> (7 - i)) & 1) == 1),
    );
    final matchCount = matches.where((m) => m).length;
    final toggleable = widget.challenge.toggleable;

    return Column(
      children: [
        const SizedBox(height: 14),
        _hud(p, matchCount),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: _onSwipe,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_numberMode) ...[
                  // A number target: per-bit marks would give the answer
                  // away, so only the number is shown.
                  _inset(
                    Text(
                      'MAKE THIS NUMBER',
                      style: _label(p.textMuted, size: 12),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Semantics(
                      label: 'Target number $target',
                      excludeSemantics: true,
                      child: Text(
                        '$target',
                        style: TextStyle(
                          fontSize: 72,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  if (widget.letter != null)
                    Center(
                      child: Text(
                        'to decode the highlighted letter',
                        style: TextStyle(fontSize: 13, color: p.textMuted),
                      ),
                    ),
                  const SizedBox(height: 20),
                ] else ...[
                  _inset(Text('TARGET', style: _label(p.textMuted, size: 12))),
                  const SizedBox(height: 10),
                  _inset(
                    Semantics(
                      label: 'Target ${RegisterState(target)}',
                      excludeSemantics: true,
                      child: _cellRow(
                        (i) => _BitCell.target(
                          on: ((target >> (7 - i)) & 1) == 1,
                          palette: p,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _inset(
                    SizedBox(
                      height: 22,
                      child: _cellRow(
                        (i) => Icon(
                          matches[i] ? Icons.check : Icons.close,
                          size: 18,
                          color: matches[i] ? p.matchHit : p.matchMiss,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    _Gutter(spilled: _lastSpillLeft, left: true, palette: p),
                    const SizedBox(width: 4),
                    Expanded(
                      child: toggleable
                          ? _cellRow((i) {
                              final index = 7 - i;
                              final on = _current.bitAt(index);
                              return Semantics(
                                button: true,
                                // A cell whose place value isn't shown on
                                // screen is named by position instead, so
                                // Hard (and Normal's hidden cells) don't
                                // give the value away to a screen reader.
                                label: _visiblePlaceValues.contains(index)
                                    ? 'Cell worth ${1 << index}, '
                                          'currently ${on ? 1 : 0}'
                                    : 'Cell ${8 - index} of 8, '
                                          'currently ${on ? 1 : 0}',
                                excludeSemantics: true,
                                child: GestureDetector(
                                  onTap: () => _toggle(index),
                                  child: _BitCell.register(on: on, palette: p),
                                ),
                              );
                            })
                          : Semantics(
                              label: _numberMode
                                  ? 'Register ${_current.bits}'
                                  : 'Register $_current, $matchCount of 8 bits match',
                              excludeSemantics: true,
                              child: _cellRow(
                                (i) => _BitCell.register(
                                  on: _current.bitAt(7 - i),
                                  palette: p,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 4),
                    _Gutter(spilled: _lastSpillRight, left: false, palette: p),
                  ],
                ),
                if (_visiblePlaceValues.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  // Easy shows every place value; Normal shows a handful
                  // that vary by puzzle, so the player has to reason out
                  // the rest; Hard leaves them all to the player.
                  ExcludeSemantics(
                    child: _inset(
                      _cellRow((i) {
                        final index = 7 - i;
                        final visible = _visiblePlaceValues.contains(index);
                        return Text(
                          visible ? '${1 << index}' : '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: p.textMuted,
                          ),
                        );
                      }),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _inset(Text('REGISTER', style: _label(p.textMuted, size: 12))),
              ],
            ),
          ),
        ),
        _controls(p),
      ],
    );
  }

  /// Lines content up with the register's columns, inside the gutters.
  Widget _inset(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28),
    child: child,
  );

  Widget _cellRow(Widget Function(int i) cell) {
    return Row(
      children: [
        for (var i = 0; i < 8; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Expanded(child: Center(child: cell(i))),
        ],
      ],
    );
  }

  Widget _hud(GameThemePalette p, int matchCount) {
    final budget = widget.challenge.moveBudget;
    final filledPips = math.min(_overflowCharge, _overflowPips);
    final ticks = _ticksRemaining;
    // The ring shows the clock when there is one, moves otherwise.
    final ringProgress = ticks != null
        ? ticks / ticksPerCycle
        : (budget == 0 ? 0.0 : _movesRemaining / budget);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _numberMode ? 'VALUE' : 'MATCH',
                  style: _label(p.textMuted),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: _numberMode ? _valueText : '$matchCount',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                      if (!_numberMode)
                        TextSpan(
                          text: ' / 8',
                          style: TextStyle(fontSize: 14, color: p.textMuted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            label: [
              if (ticks != null) '$ticks of $ticksPerCycle clock ticks left',
              '$_movesRemaining of $budget moves left',
            ].join(', '),
            excludeSemantics: true,
            child: SizedBox(
              width: 104,
              height: 104,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: ringProgress),
                duration: const Duration(milliseconds: 250),
                builder: (context, progress, child) => CustomPaint(
                  painter: _RingPainter(
                    progress: progress,
                    track: p.clockTrack,
                    fill: p.clockFill,
                  ),
                  child: child,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_movesRemaining',
                        style: TextStyle(
                          fontSize: 32,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                      SizedBox(
                        width: 68,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'OF $budget MOVES',
                            style: _label(p.textMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (widget.letter != null)
            SizedBox(
              width: 96,
              child: SignalBars(bars: widget.letter!.bars, palette: p),
            )
          else
            SizedBox(
              width: 96,
              child: Semantics(
                label: 'Overflow charge $_overflowCharge',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('OVERFLOW', style: _label(p.overflowLabel)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        for (var i = 0; i < _overflowPips; i++)
                          Padding(
                            padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                            child: _Pip(
                              filled: i < filledPips,
                              color: p.overflowAccent,
                              size: 14,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _controls(GameThemePalette p) {
    final ops = widget.challenge.allowedOperations;
    final rows = <List<OperationType>>[
      for (var i = 0; i < ops.length; i += 2)
        ops.sublist(i, math.min(i + 2, ops.length)),
    ];
    return Column(
      children: [
        if (ops.isEmpty && widget.challenge.toggleable) ...[
          Text(
            _submitNote ??
                (widget.challenge.requireSubmit
                    ? 'Switch cells between 0 and 1, then Submit'
                    : 'Tap cells to switch them between 0 and 1'),
            style: TextStyle(
              fontSize: 15,
              color: _submitNote != null ? p.matchMiss : p.textMuted,
              fontWeight: _submitNote != null ? FontWeight.w600 : null,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.challenge.requireSubmit) _submitRow(p),
          if (!widget.challenge.requireSubmit) const SizedBox(height: 8),
        ],
        if (_hasSwipe) ...[
          Text(
            'or swipe the register left or right',
            style: TextStyle(fontSize: 13, color: p.textMuted),
          ),
          const SizedBox(height: 10),
        ],
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Row(
              children: [
                for (var i = 0; i < row.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: _opButton(row[i], p)),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _submitRow(GameThemePalette p) {
    const buttonText = TextStyle(
      fontFamily: 'Sora',
      fontSize: 17,
      fontWeight: FontWeight.w600,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    return Row(
      children: [
        if (widget.challenge.hideValue) ...[
          Expanded(
            child: SizedBox(
              height: 64,
              child: OutlinedButton(
                onPressed: _test,
                style: OutlinedButton.styleFrom(
                  foregroundColor: p.textPrimary,
                  side: BorderSide(color: p.textPrimary, width: 2),
                  shape: shape,
                  textStyle: buttonText,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Test'),
                    Text(
                      _nextTestCost == 0 ? 'free' : '−$_nextTestCost pt',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: p.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: SizedBox(
            height: 64,
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: p.buttonBg,
                foregroundColor: p.buttonFg,
                shape: shape,
                textStyle: buttonText,
              ),
              child: const Text('Submit'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _opButton(OperationType op, GameThemePalette p) {
    final icon = switch (op) {
      OperationType.shiftLeft => Icons.arrow_back,
      OperationType.shiftRight => Icons.arrow_forward,
      OperationType.rotateLeft => Icons.rotate_left,
      OperationType.rotateRight => Icons.rotate_right,
      OperationType.maskAnd => Icons.filter_alt_outlined,
    };
    final trailingIcon =
        op == OperationType.shiftRight || op == OperationType.rotateRight;
    final iconWidget = Icon(icon, size: 22, color: p.buttonFg);
    return SizedBox(
      height: 64,
      child: FilledButton(
        onPressed: () => _applyOperation(op),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!trailingIcon) ...[iconWidget, const SizedBox(width: 10)],
            Flexible(child: Text(op.label, overflow: TextOverflow.ellipsis)),
            if (trailingIcon) ...[const SizedBox(width: 10), iconWidget],
          ],
        ),
      ),
    );
  }

  TextStyle _label(Color color, {double size = 11}) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w600,
    letterSpacing: size >= 12 ? 1.2 : 1,
    color: color,
  );
}

/// One bit. A 1 is a solid, raised cell; a 0 is an outlined cell — shape
/// and digit both carry the value, not color alone (SRA-BR-013).
class _BitCell extends StatelessWidget {
  const _BitCell.target({required this.on, required this.palette})
    : isTarget = true;
  const _BitCell.register({required this.on, required this.palette})
    : isTarget = false;

  final bool on;
  final bool isTarget;
  final GameThemePalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final digit = Text(
      on ? '1' : '0',
      style: TextStyle(
        fontFamily: 'IBMPlexMono',
        fontSize: isTarget ? 19 : 24,
        fontWeight: on ? FontWeight.w600 : FontWeight.w500,
        color: isTarget
            ? (on ? p.targetOnFg : p.targetOffFg)
            : (on ? p.bitOnFg : p.bitOffFg),
      ),
    );

    if (isTarget) {
      return _DashedBox(
        height: 46,
        radius: 9,
        color: on ? p.targetOnBorder : p.targetOffBorder,
        fill: on ? p.targetOnBg : null,
        child: digit,
      );
    }
    return Container(
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: on ? p.bitOnBg : p.bitOffBg,
        borderRadius: BorderRadius.circular(10),
        border: on ? null : Border.all(color: p.bitOffBorder, width: 1.5),
        boxShadow: on
            ? [BoxShadow(color: p.bitOnShadow, offset: const Offset(0, 3))]
            : null,
      ),
      child: digit,
    );
  }
}

/// A dashed rounded box for target cells — dashes mark "the goal", solid
/// cells mark "what you have".
class _DashedBox extends StatelessWidget {
  const _DashedBox({
    required this.height,
    required this.radius,
    required this.color,
    required this.child,
    this.fill,
  });

  final double height;
  final double radius;
  final Color color;
  final Color? fill;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: color, radius: radius, fill: fill),
      child: SizedBox(
        height: height,
        child: Center(child: child),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius, this.fill});

  final Color color;
  final double radius;
  final Color? fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1),
      Radius.circular(radius),
    );
    if (fill != null) {
      canvas.drawRRect(rrect, Paint()..color = fill!);
    }
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (double d = 0; d < metric.length; d += 8) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + 4, metric.length)),
          stroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.fill != fill || old.radius != radius;
}

/// A spill gutter at one end of the register: shows the last bit pushed out
/// that side — a filled pip for a 1 (it charged overflow), an outlined pip
/// for a 0, nothing before the first spill.
class _Gutter extends StatelessWidget {
  const _Gutter({
    required this.spilled,
    required this.left,
    required this.palette,
  });

  final int? spilled;
  final bool left;
  final GameThemePalette palette;

  @override
  Widget build(BuildContext context) {
    const outer = Radius.circular(12);
    const inner = Radius.circular(4);
    return Container(
      width: 24,
      height: 72,
      padding: const EdgeInsets.only(bottom: 8),
      alignment: Alignment.bottomCenter,
      decoration: BoxDecoration(
        color: palette.overflowBg,
        borderRadius: left
            ? const BorderRadius.horizontal(left: outer, right: inner)
            : const BorderRadius.horizontal(left: inner, right: outer),
      ),
      child: spilled == null
          ? null
          : _Pip(filled: spilled == 1, color: palette.overflowAccent, size: 12),
    );
  }
}

class _Pip extends StatelessWidget {
  const _Pip({required this.filled, required this.color, required this.size});

  final bool filled;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : null,
        border: filled ? null : Border.all(color: color, width: 2),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.track,
    required this.fill,
  });

  final double progress;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0;
    final rect = (Offset.zero & size).deflate(stroke / 2 + 4);
    final base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, 2 * math.pi, false, base);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        base
          ..color = fill
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track || old.fill != fill;
}

class _Outcome {
  const _Outcome({required this.won, required this.timedOut});

  final bool won;
  final bool timedOut;
}
