import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app_services.dart';
import 'screens/home_screen.dart';

void main() {
  LicenseRegistry.addLicense(_fontLicenses);
  runApp(const ShiftRegisterArcadeApp());
}

/// The bundled fonts' OFL texts, so they show on the in-app licences page
/// (the OFL requires the licence to travel with the fonts).
Stream<LicenseEntry> _fontLicenses() async* {
  yield LicenseEntryWithLineBreaks(
      ['Sora'], await rootBundle.loadString('assets/fonts/Sora-OFL.txt'));
  yield LicenseEntryWithLineBreaks(['IBM Plex Mono'],
      await rootBundle.loadString('assets/fonts/IBMPlexMono-OFL.txt'));
}

class ShiftRegisterArcadeApp extends StatefulWidget {
  const ShiftRegisterArcadeApp({super.key, AppServices? services})
      : _injectedServices = services;

  /// Tests inject fakes here instead of letting the real
  /// UMP/AdMob/IAP services run — see game-shell's README: "Widget tests
  /// should construct the Fake* services directly."
  final AppServices? _injectedServices;

  @override
  State<ShiftRegisterArcadeApp> createState() =>
      _ShiftRegisterArcadeAppState();
}

class _ShiftRegisterArcadeAppState extends State<ShiftRegisterArcadeApp> {
  late final _services = widget._injectedServices ?? AppServices();
  late final Future<void> _ready = _services.initialize();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shift-Register Arcade',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        fontFamily: 'Sora',
      ),
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
    );
  }
}
