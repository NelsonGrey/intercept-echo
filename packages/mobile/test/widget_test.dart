import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_shell/game_shell.dart';
import 'package:shift_register_arcade/app/app_services.dart';
import 'package:shift_register_arcade/main.dart';

// Real UMP/AdMob/IAP services need platform plugin channels a widget test
// doesn't have, so every test here injects the Fake* services (matching
// game-shell's own testing guidance) rather than booting the real ones.
AppServices fakeServices() => AppServices(
      consent: FakeConsentService(),
      entitlement: FakeEntitlementService(),
      ads: FakeAdService(),
    );

void main() {
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

    expect(find.text('First Shift'), findsOneWidget);
  });

  testWidgets('solving a challenge hides the banner, then shows results',
      (tester) async {
    final services = fakeServices();
    await tester.pumpWidget(ShiftRegisterArcadeApp(services: services));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('First Shift'));
    await tester.pumpAndSettle();

    // Active gameplay: no banner.
    expect(find.byKey(const Key('fake_banner_ad')), findsNothing);

    // move-01: 0x01 --shiftLeft--> 0x02, budget 1 — one tap wins it.
    await tester.tap(find.text('Shift Left'));
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
    await tester.tap(find.text('Three Steps'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fake_banner_ad')), findsNothing);

    await tester.tap(find.byIcon(Icons.pause));
    await tester.pumpAndSettle();

    expect(find.text('Paused'), findsOneWidget);
    expect(find.byKey(const Key('fake_banner_ad')), findsOneWidget);
  });
}
