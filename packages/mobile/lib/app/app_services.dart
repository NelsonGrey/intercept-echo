import 'dart:io';

import 'package:game_shell/game_shell.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../intercept/intercept_run.dart';
import '../settings/difficulty_setting.dart';
import '../settings/relaxed_clock_setting.dart';
import '../theme/theme_controller.dart';

/// Opens a URL in the device's browser. A function, not a call straight to
/// `url_launcher`, so widget tests can inject a fake instead of hitting a
/// real platform channel.
typedef UrlOpener = Future<void> Function(Uri url);

Future<void> _defaultOpenUrl(Uri url) => url_launcher.launchUrl(
  url,
  mode: url_launcher.LaunchMode.externalApplication,
);

/// Portfolio-standard game-shell services for this app, wired per the
/// game-shell README's "Wiring order". Real AdMob IDs aren't provisioned
/// yet (no Play Console / App Store Connect listing — see
/// docs/STORE_SETUP.md), so this uses [AdMobConfig.test] for now; swap in
/// this game's real config once those exist.
class AppServices {
  AppServices({
    ConsentService? consent,
    EntitlementService? entitlement,
    AdService? ads,
    PlatformGameAuthService? auth,
    ThemeController? theme,
    RelaxedClockSetting? relaxedClock,
    InterceptRun? intercept,
    DifficultySetting? difficulty,
    UrlOpener? openUrl,
  }) : difficulty = difficulty ?? DifficultySetting(),
       intercept = intercept ?? InterceptRun(),
       theme = theme ?? ThemeController(),
       relaxedClock = relaxedClock ?? RelaxedClockSetting(),
       openUrl = openUrl ?? _defaultOpenUrl,
       consent = consent ?? UmpConsentService(),
       entitlement =
           entitlement ??
           IapEntitlementService(adRemovalProductId: 'ad_removal'),
       ads = ads ?? AdMobAdService(AdMobConfig.test()),
       auth = auth ?? _defaultAuth();

  final ConsentService consent;
  final EntitlementService entitlement;
  final AdService ads;

  /// Game Center on iOS/macOS. Android falls back to a fake — Play Games
  /// Services isn't wired up yet (no tester group; see README status).
  final PlatformGameAuthService auth;

  static PlatformGameAuthService _defaultAuth() =>
      (Platform.isIOS || Platform.isMacOS)
      ? GameCenterAuthService()
      : FakePlatformGameAuthService();

  /// The player's gameplay palette. Not a game-shell service — it lives
  /// here so every screen reaches it the same way.
  final ThemeController theme;

  /// Accessibility: doubles clock ticks when on.
  final RelaxedClockSetting relaxedClock;

  /// Easy shows cell place values; Hard hides them.
  final DifficultySetting difficulty;

  /// Campaign progress through the Intercept transmissions.
  final InterceptRun intercept;

  /// Opens the Privacy/Terms/Support links in Settings.
  final UrlOpener openUrl;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await theme.load();
    await relaxedClock.load();
    await difficulty.load();
    await intercept.load();
    await consent.requestConsent();
    await entitlement.restore();

    // Best-effort: a failed/declined platform sign-in (e.g. no Game Center
    // account on this device) shouldn't block the app from starting.
    try {
      await auth.signIn();
    } catch (_) {
      // Swallowed deliberately — see comment above.
    }

    if (consent.canRequestAds) {
      await ads.initialize();
    }
    ads.setAdFree(entitlement.isAdFree);
    entitlement.adFreeChanges.listen(ads.setAdFree);
  }
}
