import 'package:flutter/material.dart';
import 'package:game_shell/game_shell.dart';

import '../app/app_services.dart';
import '../content/challenge_repository.dart';
import 'gameplay_screen.dart';

class ChallengeSelectScreen extends StatelessWidget {
  const ChallengeSelectScreen({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Challenges')),
      body: GameScreenShell(
        adService: services.ads,
        body: ListView.builder(
          itemCount: ChallengeRepository.all.length,
          itemBuilder: (context, index) {
            final challenge = ChallengeRepository.all[index];
            return ListTile(
              title: Text(challenge.title),
              subtitle: Text('${challenge.chapter} · budget ${challenge.moveBudget}'),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => GameplayScreen(
                    services: services,
                    challenge: challenge,
                  ),
                ));
              },
            );
          },
        ),
      ),
    );
  }
}
