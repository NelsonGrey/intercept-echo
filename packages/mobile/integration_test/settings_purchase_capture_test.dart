import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intercept_echo/app/app_services.dart';
import 'package:intercept_echo/gamecenter/fake_game_center_progress_service.dart';
import 'package:intercept_echo/gamecenter/game_center_connection.dart';
import 'package:intercept_echo/main.dart';
import 'package:intercept_echo/shell/shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppServices _captureServices() {
  return AppServices(
    consent: FakeConsentService(),
    entitlement: FakeEntitlementService(),
    ads: _CaptureAdService(),
    auth: FakePlatformGameAuthService(),
    connection: GameCenterConnection.unsupportedFake(),
    progress: FakeGameCenterProgressService(),
    openUrl: (_) async {},
  );
}

class _CaptureAdService implements AdService {
  @override
  Widget buildBanner() => const SizedBox.shrink();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> initialize() async {}

  @override
  bool get isAdFree => false;

  @override
  void preloadInterstitial() {}

  @override
  void setAdFree(bool adFree) {}

  @override
  Future<void> showInterstitial() async {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('hold Settings purchase option for native capture', (
    tester,
  ) async {
    await tester.pumpWidget(InterceptEchoApp(services: _captureServices()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    final purchaseButton = find.widgetWithText(
      FilledButton,
      'Remove Ads — \$2.99',
    );
    await tester.scrollUntilVisible(purchaseButton, 100);
    await tester.ensureVisible(purchaseButton);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -360));
    await tester.pumpAndSettle();

    expect(find.text('Purchases'), findsOneWidget);
    expect(find.text('Ads on'), findsOneWidget);
    expect(purchaseButton, findsOneWidget);
    expect(find.text('Restore Purchases'), findsOneWidget);

    debugPrint('CAPTURE_READY_SETTINGS_PURCHASE');
    await tester.pump(const Duration(seconds: 20));
  });
}
