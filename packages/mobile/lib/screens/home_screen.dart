import 'package:flutter/material.dart';
import '../shell/shell.dart';

import 'challenge_select_screen.dart';
import 'game_center_widgets.dart';
import 'message_board_screen.dart';
import 'settings_screen.dart';
import '../app/app_services.dart';
import '../theme/intercept_echo_brand.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppServices get services => widget.services;

  @override
  void initState() {
    super.initState();
    // First visit only: offer Game Center once, after the screen is up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && services.connection.shouldPrompt) {
        showGameCenterPrompt(context, services.connection);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: services.theme,
      builder: (context, _) {
        final p = services.theme.palette;
        return Scaffold(
          backgroundColor: p.pageBg,
          body: GameScreenShell(
            adService: services.ads,
            body: EchoBackdrop(
              palette: p,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      Semantics(
                        header: true,
                        label: 'Intercept Echo',
                        child: ExcludeSemantics(
                          child: Image.asset(
                            'assets/branding/intercept-echo-wordmark.png',
                            width: 330,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'SHIFT BITS  •  CRACK TRANSMISSIONS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: p.textMuted,
                          fontFamily: 'IBMPlexMono',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(flex: 2),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    MessageBoardScreen(services: services),
                              ),
                            );
                          },
                          icon: const Icon(Icons.graphic_eq),
                          label: const Text('Play'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ChallengeSelectScreen(services: services),
                                ),
                              );
                            },
                            icon: const Icon(Icons.tune),
                            label: const Text('Practice'),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SettingsScreen(services: services),
                                ),
                              );
                            },
                            icon: const Icon(Icons.settings_outlined),
                            label: const Text('Settings'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GameCenterBadge(services: services),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
