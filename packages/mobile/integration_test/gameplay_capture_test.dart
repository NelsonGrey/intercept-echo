import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_shell/game_shell.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intercept_echo/app/app_services.dart';
import 'package:intercept_echo/gamecenter/fake_game_center_progress_service.dart';
import 'package:intercept_echo/gamecenter/game_center_connection.dart';
import 'package:intercept_echo/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppServices _captureServices() {
  final ads = FakeAdService()..setAdFree(true);
  return AppServices(
    consent: FakeConsentService(),
    entitlement: FakeEntitlementService(),
    ads: ads,
    auth: FakePlatformGameAuthService(),
    connection: GameCenterConnection.connectedFake(),
    progress: FakeGameCenterProgressService(),
    openUrl: (_) async {},
  );
}

Future<void> _hold(WidgetTester tester, [int milliseconds = 1100]) async {
  await tester.pump(Duration(milliseconds: milliseconds));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('capture a complete Intercept gameplay loop', (tester) async {
    final services = _captureServices();
    await services.entitlement.purchaseAdRemoval();
    await tester.pumpWidget(InterceptEchoApp(services: services));
    await tester.pumpAndSettle();
    await _hold(tester, 1600);

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    await _hold(tester, 1400);

    await tester.tap(find.text('Crack next letter'));
    await tester.pumpAndSettle();
    await _hold(tester, 1400);

    // Decode S: A=1, so S is register value 19 (16 + 2 + 1).
    for (final value in [16, 2, 1]) {
      await tester.tap(find.bySemanticsLabel('Cell worth $value, currently 0'));
      await tester.pump(const Duration(milliseconds: 450));
    }
    await _hold(tester, 800);

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    await _hold(tester, 1500);

    await tester.tap(find.text('Back to the message'));
    await tester.pumpAndSettle();
    await _hold(tester, 1400);

    await tester.tap(find.text('Guess the message'));
    await tester.pumpAndSettle();
    await _hold(tester, 1200);

    // The cracked S is fixed; fill the remaining slots to decode SIGNAL FOUND.
    for (final letter in 'IGNALFOUND'.split('')) {
      await tester.tap(find.widgetWithText(TextButton, letter));
      await tester.pump(const Duration(milliseconds: 220));
    }
    await _hold(tester, 700);

    await tester.tap(find.text('Submit guess'));
    await tester.pumpAndSettle();
    await _hold(tester, 1500);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await _hold(tester, 1700);

    await tester.tap(find.text('Next transmission'));
    await tester.pumpAndSettle();
    await _hold(tester, 1500);

    expect(find.text('TRANSMISSION 2 OF 50'), findsOneWidget);
  });
}
