import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_shell/game_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shift_register_arcade/app/app_services.dart';
import 'package:shift_register_arcade/main.dart';

AppServices fakeServices() => AppServices(
  consent: FakeConsentService(),
  entitlement: FakeEntitlementService(),
  ads: FakeAdService(),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<AppServices> openBoard(WidgetTester tester) async {
    // A phone-sized surface, as the game is iPhone-only.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final services = fakeServices();
    await tester.pumpWidget(ShiftRegisterArcadeApp(services: services));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    return services;
  }

  testWidgets('Play opens the first transmission with the banner', (
    tester,
  ) async {
    await openBoard(tester);
    expect(find.text('TRANSMISSION 1 OF 12'), findsOneWidget);
    expect(find.text('Crack next letter'), findsOneWidget);
    expect(find.byKey(const Key('fake_banner_ad')), findsOneWidget);
  });

  testWidgets('cracking a letter reveals it on the board, with no ad', (
    tester,
  ) async {
    final services = await openBoard(tester);
    await tester.tap(find.text('Crack next letter'));
    await tester.pumpAndSettle();

    // S = 19 = 16 + 2 + 1 under the tutorial cipher.
    expect(find.text('LETTER 1 OF 10'), findsOneWidget);
    expect(find.byKey(const Key('fake_banner_ad')), findsNothing);
    for (final v in [16, 2, 1]) {
      await tester.tap(find.bySemanticsLabel('Cell worth $v, currently 0'));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('Letter cracked'), findsOneWidget);
    expect(find.text('19 = S'), findsOneWidget);

    await tester.tap(find.text('Back to the message'));
    await tester.pumpAndSettle();
    expect(services.intercept.revealed, {'S'});
    expect((services.ads as FakeAdService).interstitialShownCount, 0);
    expect(find.text('TRANSMISSION 1 OF 12'), findsOneWidget);
  });

  testWidgets('leaving a letter early costs a signal bar', (tester) async {
    final services = await openBoard(tester);
    await tester.tap(find.text('Crack next letter'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back to the message'));
    await tester.pumpAndSettle();
    expect(find.text('Leave this letter?'), findsOneWidget);
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();

    expect(services.intercept.bars, 3);
    expect(services.intercept.revealed, isEmpty);
  });

  testWidgets('a right guess shows first, then one ad, then the result', (
    tester,
  ) async {
    final services = await openBoard(tester);
    await tester.tap(find.text('Guess the message'));
    await tester.pumpAndSettle();

    for (final ch in 'SIGNALFOUND'.split('')) {
      await tester.tap(find.widgetWithText(TextButton, ch));
      await tester.pump();
    }
    await tester.tap(find.text('Submit guess'));
    await tester.pumpAndSettle();

    final ads = services.ads as FakeAdService;
    expect(find.text('Message decoded!'), findsOneWidget);
    expect(ads.interstitialShownCount, 0);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(ads.interstitialShownCount, 1);
    expect(find.text('Decoded: guessed early!'), findsOneWidget);

    await tester.tap(find.text('Next transmission'));
    await tester.pumpAndSettle();
    expect(find.text('TRANSMISSION 2 OF 12'), findsOneWidget);
    expect(ads.interstitialShownCount, 1);
  });

  testWidgets('a wrong guess costs a bar and returns to the board', (
    tester,
  ) async {
    final services = await openBoard(tester);
    await tester.tap(find.text('Guess the message'));
    await tester.pumpAndSettle();
    for (final ch in 'SIGNALLOSTX'.split('')) {
      await tester.tap(find.widgetWithText(TextButton, ch));
      await tester.pump();
    }
    await tester.tap(find.text('Submit guess'));
    await tester.pumpAndSettle();
    expect(find.text('Not the message'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(services.intercept.bars, 3);
    expect(find.text('Crack next letter'), findsOneWidget);
  });
}
