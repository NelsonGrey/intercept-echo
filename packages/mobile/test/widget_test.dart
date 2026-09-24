import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_shell/game_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shift_register_arcade/app/app_services.dart';
import 'package:shift_register_arcade/main.dart';
import 'package:shift_register_arcade/theme/game_theme.dart';

// Real UMP/AdMob/IAP services need platform plugin channels a widget test
// doesn't have, so every test here injects the Fake* services (matching
// game-shell's own testing guidance) rather than booting the real ones.
AppServices fakeServices() => AppServices(
      consent: FakeConsentService(),
      entitlement: FakeEntitlementService(),
      ads: FakeAdService(),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('boots to the home screen and shows the banner', (tester) async {
    await tester.pumpWidget(ShiftRegisterArcadeApp(services: fakeServices()));
    await tester.pumpAndSettle();

    expect(find.text('Shift-Register Arcade'), findsOneWidget);
    expect(find.byKey(const Key('fake_banner_ad')), findsOneWidget);
  });

  testWidgets('Play navigates to the challenge list', (tester) async {
    await tester.pumpWidget(ShiftRegisterArcadeApp(services: fakeServices()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();

    expect(find.text('Make 2'), findsOneWidget);
  });

  testWidgets('solving a challenge hides the banner, then shows results',
      (tester) async {
    final services = fakeServices();
    await tester.pumpWidget(ShiftRegisterArcadeApp(services: services));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Make 2'));
    await tester.pumpAndSettle();

    // Active gameplay: no banner.
    expect(find.byKey(const Key('fake_banner_ad')), findsNothing);

    // count-01: start 0, make 2 — tapping the cell worth 2 wins it.
    await tester.tap(find.bySemanticsLabel('Cell worth 2, currently 0'));
    await tester.pumpAndSettle();

    expect(find.text('Target Matched'), findsOneWidget);
    expect((services.ads as FakeAdService).interstitialShownCount, 1);
    // Round-exit interstitial fired, but the results screen's own banner
    // should still be showing.
    expect(find.byKey(const Key('fake_banner_ad')), findsOneWidget);
  });

  testWidgets('pausing shows the banner mid-round', (tester) async {
    await tester.pumpWidget(ShiftRegisterArcadeApp(services: fakeServices()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Make 1'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fake_banner_ad')), findsNothing);

    await tester.tap(find.byIcon(Icons.pause));
    await tester.pumpAndSettle();

    expect(find.text('Paused'), findsOneWidget);
    expect(find.byKey(const Key('fake_banner_ad')), findsOneWidget);
  });

  testWidgets('choosing a palette recolors gameplay and persists',
      (tester) async {
    final services = fakeServices();
    await tester.pumpWidget(ShiftRegisterArcadeApp(services: services));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arcade Neon'));
    await tester.pumpAndSettle();

    expect(services.theme.value, GameThemeId.arcadeNeon);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('gameplay.theme'), 'arcadeNeon');

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Make 2'));
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor,
        gameThemePalettes[GameThemeId.arcadeNeon]!.pageBg);
  });

  testWidgets('a saved palette loads on launch; an unknown one falls back',
      (tester) async {
    SharedPreferences.setMockInitialValues({'gameplay.theme': 'warmSunset'});
    final services = fakeServices();
    await tester.pumpWidget(ShiftRegisterArcadeApp(services: services));
    await tester.pumpAndSettle();
    expect(services.theme.value, GameThemeId.warmSunset);

    SharedPreferences.setMockInitialValues({'gameplay.theme': 'retired'});
    await services.theme.load();
    expect(services.theme.value, defaultGameTheme);
  });

  group('round clock', () {
    Future<AppServices> openChallenge(WidgetTester tester, String title) async {
      final services = fakeServices();
      await tester.pumpWidget(ShiftRegisterArcadeApp(services: services));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text(title), 200);
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      return services;
    }

    // Make 3 is a clocked Count challenge: 8 ticks of 1.5s.
    const tick = Duration(milliseconds: 1500);

    testWidgets('a clocked round fails as Out of Time after 8 ticks',
        (tester) async {
      final services = await openChallenge(tester, 'Make 3');

      await tester.pump(tick * 7);
      expect(find.text('Out of Time'), findsNothing);

      await tester.pump(tick);
      await tester.pumpAndSettle();
      expect(find.text('Out of Time'), findsOneWidget);
      expect((services.ads as FakeAdService).interstitialShownCount, 1);
    });

    testWidgets('pausing stops the clock', (tester) async {
      await openChallenge(tester, 'Make 3');

      await tester.pump(tick * 3);
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump(const Duration(minutes: 1));
      expect(find.text('Paused'), findsOneWidget);
      expect(find.text('Out of Time'), findsNothing);

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump(tick * 4);
      expect(find.text('Out of Time'), findsNothing);
      await tester.pump(tick);
      await tester.pumpAndSettle();
      expect(find.text('Out of Time'), findsOneWidget);
    });

    testWidgets('relaxed clock doubles every tick', (tester) async {
      SharedPreferences.setMockInitialValues(
          {'accessibility.relaxedClock': true});
      await openChallenge(tester, 'Make 3');

      await tester.pump(tick * 8);
      expect(find.text('Out of Time'), findsNothing);

      await tester.pump(tick * 8);
      await tester.pumpAndSettle();
      expect(find.text('Out of Time'), findsOneWidget);
    });

    testWidgets('the opening challenges have no clock', (tester) async {
      await openChallenge(tester, 'Make 2');
      await tester.pump(const Duration(minutes: 5));
      expect(find.text('Out of Time'), findsNothing);
      expect(find.text('MAKE THIS NUMBER'), findsOneWidget);
    });

    testWidgets('Shift reaches a number by doubling', (tester) async {
      await openChallenge(tester, 'Double');
      // shift-01: 3 -> 6 is one Shift Left.
      await tester.tap(find.text('Shift Left'));
      await tester.pumpAndSettle();
      expect(find.text('Target Matched'), findsOneWidget);
    });

    testWidgets('a wrong toggle costs a move and can be undone',
        (tester) async {
      await openChallenge(tester, 'Make 2');
      // count-01 budget is 3: tap 1 (wrong), tap 1 again (undo), tap 2.
      await tester.tap(find.bySemanticsLabel('Cell worth 1, currently 0'));
      await tester.pump();
      expect(find.text('Target Matched'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Cell worth 1, currently 1'));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Cell worth 2, currently 0'));
      await tester.pumpAndSettle();
      expect(find.text('Target Matched'), findsOneWidget);
    });

    testWidgets('the relaxed clock toggle persists', (tester) async {
      final services = fakeServices();
      await tester.pumpWidget(ShiftRegisterArcadeApp(services: services));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Relaxed clock'), 100);
      await tester.tap(find.text('Relaxed clock'));
      await tester.pumpAndSettle();

      expect(services.relaxedClock.value, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('accessibility.relaxedClock'), isTrue);
    });
  });
}
