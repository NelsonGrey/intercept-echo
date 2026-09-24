import 'package:flutter/material.dart';
import 'package:game_shell/game_shell.dart';

import 'challenge_select_screen.dart';
import 'settings_screen.dart';
import '../app/app_services.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameScreenShell(
        adService: services.ads,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Shift-Register Arcade',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ChallengeSelectScreen(services: services),
                  ));
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: Text('Play'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => SettingsScreen(services: services),
                  ));
                },
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
