import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_shell/game_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intercept_echo/app/app_services.dart';
import 'package:intercept_echo/gamecenter/fake_game_center_progress_service.dart';
import 'package:intercept_echo/gamecenter/game_center_connection.dart';
import 'package:intercept_echo/main.dart';

AppServices _services() => AppServices(
  consent: FakeConsentService(),
  entitlement: FakeEntitlementService(),
  ads: FakeAdService(),
  auth: FakePlatformGameAuthService(),
  connection: GameCenterConnection.connectedFake(),
  progress: FakeGameCenterProgressService(),
  openUrl: (_) async {},
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('render Intercept Echo previews', (tester) async {
    final sora = FontLoader('Sora')
      ..addFont(rootBundle.load('assets/fonts/Sora-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Sora-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Sora-Bold.ttf'));
    final mono = FontLoader('IBMPlexMono')
      ..addFont(rootBundle.load('assets/fonts/IBMPlexMono-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/IBMPlexMono-SemiBold.ttf'));
    await Future.wait([sora.load(), mono.load()]);

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(InterceptEchoApp(services: _services()));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/intercept_echo_home.png'),
    );

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/intercept_echo_transmission.png'),
    );

    await tester.tap(find.text('Crack next letter'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/intercept_echo_gameboard.png'),
    );
  });
}
