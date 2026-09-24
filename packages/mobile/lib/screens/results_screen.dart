import 'package:flutter/material.dart';
import 'package:game_shell/game_shell.dart';

import '../app/app_services.dart';
import '../content/challenge.dart';
import '../content/challenge_repository.dart';
import 'gameplay_screen.dart';

/// Reached only on the way *out* of a round (win or fail) — this is the
/// non-gameplay screen the portfolio's ad-placement rule calls the
/// interstitial "round-exit" moment. The interstitial itself is fired by
/// the caller right before pushing this screen (see GameplayScreen), not
/// from here, so this screen only needs to show the banner like any other
/// non-gameplay screen.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({
    super.key,
    required this.services,
    required this.challenge,
    required this.won,
    required this.movesUsed,
    this.timedOut = false,
  });

  final AppServices services;
  final Challenge challenge;
  final bool won;
  final int movesUsed;

  /// The round clock ran out (as opposed to the move budget).
  final bool timedOut;

  /// The challenge after this one in the list, or null at the end.
  Challenge? get _next {
    final all = ChallengeRepository.all;
    final i = all.indexWhere((c) => c.id == challenge.id);
    return i >= 0 && i + 1 < all.length ? all[i + 1] : null;
  }

  void _play(BuildContext context, Challenge c) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => GameplayScreen(services: services, challenge: c),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final next = _next;
    return Scaffold(
      body: GameScreenShell(
        adService: services.ads,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                won
                    ? 'Target Matched'
                    : (timedOut ? 'Out of Time' : 'Out of Moves'),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: won ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text('${challenge.title} · $movesUsed/${challenge.moveBudget} moves'),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                    child: const Text('Menu'),
                  ),
                  const SizedBox(width: 16),
                  (won && next != null ? OutlinedButton.new : FilledButton.new)(
                    onPressed: () => _play(context, challenge),
                    child: const Text('Retry'),
                  ),
                  if (won && next != null) ...[
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: () => _play(context, next),
                      child: const Text('Next'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
