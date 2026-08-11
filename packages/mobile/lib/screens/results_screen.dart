import 'package:flutter/material.dart';
import 'package:game_shell/game_shell.dart';

import '../app/app_services.dart';
import '../content/challenge.dart';
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
  });

  final AppServices services;
  final Challenge challenge;
  final bool won;
  final int movesUsed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameScreenShell(
        adService: services.ads,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                won ? 'Target Matched' : 'Out of Moves',
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
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (_) => GameplayScreen(
                          services: services,
                          challenge: challenge,
                        ),
                      ));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
