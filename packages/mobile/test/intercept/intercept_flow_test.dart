import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_shell/game_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intercept_echo/app/app_services.dart';
import 'package:intercept_echo/gamecenter/fake_game_center_progress_service.dart';
import 'package:intercept_echo/gamecenter/game_center_progress_service.dart';
import 'package:intercept_echo/main.dart';

AppServices fakeServices() => AppServices(
  consent: FakeConsentService(),
  entitlement: FakeEntitlementService(),
  ads: FakeAdService(),
  auth: FakePlatformGameAuthService(),
  progress: FakeGameCenterProgressService(),
  openUrl: (_) async {},
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Sets the register to [value] by tapping whichever cells differ.
  Future<void> setRegister(WidgetTester tester, int value) async {
    for (var bit = 7; bit >= 0; bit--) {
      final worth = 1 << bit;
      final want = (value >> bit) & 1;
      final wrong = find.bySemanticsLabel(
        'Cell worth $worth, currently ${1 - want}',
      );
      if (wrong.evaluate().isNotEmpty) {
        await tester.tap(wrong);
        await tester.pump();
      }
    }
  }

  Future<AppServices> openBoard(WidgetTester tester) async {
    // A phone-sized surface, as the game is iPhone-only.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final services = fakeServices();
    await tester.pumpWidget(InterceptEchoApp(services: services));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    return services;
  }

  testWidgets('Play opens the first transmission with the banner', (
    tester,
  ) async {
    await openBoard(tester);
    expect(find.text('TRANSMISSION 1 OF 50'), findsOneWidget);
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
    // Matching the target is not enough: the answer is committed with Submit.
    expect(find.text('Letter cracked'), findsNothing);
    expect(find.text('19'), findsWidgets); // tutorial shows the live value
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(find.text('Letter cracked'), findsOneWidget);
    expect(find.text('19 = S'), findsOneWidget);

    await tester.tap(find.text('Back to the message'));
    await tester.pumpAndSettle();
    expect(services.intercept.revealed, {'S'});
    expect((services.ads as FakeAdService).interstitialShownCount, 0);
    expect(find.text('TRANSMISSION 1 OF 50'), findsOneWidget);
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
    expect(find.text('TRANSMISSION 2 OF 50'), findsOneWidget);
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

  testWidgets('a wrong Submit costs a move and says so', (tester) async {
    await openBoard(tester);
    await tester.tap(find.text('Crack next letter'));
    await tester.pumpAndSettle();
    // S = 19; submit 16 instead.
    await tester.tap(find.bySemanticsLabel('Cell worth 16, currently 0'));
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await tester.pump();
    expect(find.text("That's not it. −1 move"), findsOneWidget);
    expect(find.text('Letter cracked'), findsNothing);
  });

  testWidgets('keyed messages hide the value; Test is free once, then 1 pt', (
    tester,
  ) async {
    // Transmission 4, "KEY HAS CHANGED": key 3, Count puzzles.
    SharedPreferences.setMockInitialValues({'intercept.index': 3});
    final services = await openBoard(tester);
    expect(find.text('TRANSMISSION 4 OF 50'), findsOneWidget);
    await tester.tap(find.text('Crack next letter'));
    await tester.pumpAndSettle();

    // Two '?': the highlighted blank in the message and the hidden value.
    expect(find.text('?'), findsNWidgets(2));
    expect(find.text('free'), findsOneWidget);
    await tester.tap(find.text('Test'));
    await tester.pump();
    expect(find.text('?'), findsOneWidget); // the value is now shown
    expect(find.text('−1 pt'), findsOneWidget);
    await tester.tap(find.text('Test'));
    await tester.pump();

    // K = 11th letter + key 3 = 14.
    final target = services.intercept.current.cipher.codeFor('K');
    expect(target, 14);
    await setRegister(tester, target);
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to the message'));
    await tester.pumpAndSettle();

    // 100 per letter + 20 x 1 spare move - 1 for the second Test.
    expect(services.intercept.revealed, {'K'});
    expect(services.intercept.totalScore, 100 + 20 - 1);
  });

  testWidgets('Easy shows cell values; Hard hides them and is saved', (
    tester,
  ) async {
    final services = await openBoard(tester);
    await tester.tap(find.text('Crack next letter'));
    await tester.pumpAndSettle();
    expect(find.text('128'), findsOneWidget); // Easy is the default
    expect(find.bySemanticsLabel('Cell worth 16, currently 0'), findsOneWidget);

    // Leave the letter (costs a bar), go to Settings, choose Hard.
    await tester.tap(find.byTooltip('Back to the message'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Hard'), 100);
    await tester.tap(find.text('Hard'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('gameplay.difficulty'), 'hard');
    final progress = services.progress as FakeGameCenterProgressService;
    expect(
      progress.unlockedAchievements,
      contains(GameCenterIds.achievementHardDifficulty),
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crack next letter'));
    await tester.pumpAndSettle();
    expect(find.text('128'), findsNothing);
    expect(find.bySemanticsLabel('Cell 4 of 8, currently 0'), findsOneWidget);
    expect(services.difficulty.visiblePlaceValues('anything'), isEmpty);
  });

  testWidgets('Normal shows some cell values, not all, not none', (
    tester,
  ) async {
    await openBoard(tester);
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Normal'), 100);
    await tester.tap(find.text('Normal'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('gameplay.difficulty'), 'normal');

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crack next letter'));
    await tester.pumpAndSettle();

    final worthFinder = find.bySemanticsLabel(RegExp(r'^Cell worth \d+,'));
    expect(worthFinder.evaluate().length, inInclusiveRange(3, 5));
  });
}
