import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app_services.dart';
import 'screens/home_screen.dart';
import 'theme/game_theme.dart';

void main() {
  LicenseRegistry.addLicense(_fontLicenses);
  runApp(const InterceptEchoApp());
}

/// The bundled fonts' OFL texts, so they show on the in-app licences page
/// (the OFL requires the licence to travel with the fonts).
Stream<LicenseEntry> _fontLicenses() async* {
  yield LicenseEntryWithLineBreaks([
    'Sora',
  ], await rootBundle.loadString('assets/fonts/Sora-OFL.txt'));
  yield LicenseEntryWithLineBreaks([
    'IBM Plex Mono',
  ], await rootBundle.loadString('assets/fonts/IBMPlexMono-OFL.txt'));
}

class InterceptEchoApp extends StatefulWidget {
  const InterceptEchoApp({super.key, AppServices? services})
    : _injectedServices = services;

  /// Tests inject fakes here instead of letting the real
  /// UMP/AdMob/IAP services run — see game-shell's README: "Widget tests
  /// should construct the Fake* services directly."
  final AppServices? _injectedServices;

  @override
  State<InterceptEchoApp> createState() => _InterceptEchoAppState();
}

class _InterceptEchoAppState extends State<InterceptEchoApp> {
  late final _services = widget._injectedServices ?? AppServices();
  late final Future<void> _ready = _services.initialize();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _services.theme,
      builder: (context, id, _) => MaterialApp(
        title: 'Intercept Echo',
        theme: materialThemeFor(gameThemePalettes[id]!),
        home: FutureBuilder<void>(
          future: _ready,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return HomeScreen(services: _services);
          },
        ),
      ),
    );
  }
}
