import 'package:flutter/material.dart';
import 'package:game_shell/game_shell.dart';

import '../app/app_services.dart';
import '../content/challenge.dart';
import '../domain/operation_type.dart';
import '../domain/register_engine.dart';
import '../domain/register_state.dart';
import 'results_screen.dart';

/// The one gameplay screen in this vertical slice. Ad placement here
/// follows the portfolio rule (see game-shell's README "Ad placement
/// policy"): the banner is hidden while [_isPaused] is false (active
/// target resolution) and shown the instant the player pauses — same
/// route, dynamically toggled `showBanner`, not two separate screens. The
/// interstitial is fired once, right before navigating to [ResultsScreen]
/// on win or fail — never before the round starts.
class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key, required this.services, required this.challenge});

  final AppServices services;
  final Challenge challenge;

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  late RegisterState _current;
  late int _movesRemaining;
  bool _isPaused = false;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _current = RegisterState(widget.challenge.initialBits);
    _movesRemaining = widget.challenge.moveBudget;
    widget.services.ads.preloadInterstitial();
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
    });
    _checkResolution();
  }

  void _checkResolution() {
    final target = widget.challenge.targetBits;
    if (_current.bits == target) {
      _finish(won: true);
    } else if (_movesRemaining <= 0) {
      _finish(won: false);
    }
  }

  Future<void> _finish({required bool won}) async {
    if (_resolved) return;
    _resolved = true;
    final movesUsed = widget.challenge.moveBudget - _movesRemaining;

    // Round-exit: exactly one interstitial, on the way to a non-gameplay
    // screen, never gating the round that just ended.
    await widget.services.ads.showInterstitial();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ResultsScreen(
        services: widget.services,
        challenge: widget.challenge,
        won: won,
        movesUsed: movesUsed,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.challenge.title),
        actions: [
          IconButton(
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: () => setState(() => _isPaused = !_isPaused),
          ),
        ],
      ),
      body: GameScreenShell(
        adService: widget.services.ads,
        // Dynamic per the ad-placement rule: banner appears the instant
        // the player pauses, disappears the instant they resume.
        showBanner: _isPaused,
        body: _isPaused
            ? const Center(child: Text('Paused'))
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Target'),
                    _RegisterRow(state: RegisterState(widget.challenge.targetBits)),
                    const SizedBox(height: 24),
                    const Text('Register'),
                    _RegisterRow(state: _current),
                    const SizedBox(height: 16),
                    Text('Moves remaining: $_movesRemaining'),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 12,
                      children: widget.challenge.allowedOperations
                          .map((op) => FilledButton(
                                onPressed: () => _applyOperation(op),
                                child: Text(op.label),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _RegisterRow extends StatelessWidget {
  const _RegisterRow({required this.state});

  final RegisterState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(8, (i) {
        final index = 7 - i;
        final isOne = state.bitAt(index);
        return Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.all(2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isOne ? Colors.deepPurple : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isOne ? '1' : '0',
            style: TextStyle(
              color: isOne ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }),
    );
  }
}
