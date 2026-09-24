import 'package:game_shell/game_shell.dart';

import '../intercept/intercept_run.dart';
import '../settings/relaxed_clock_setting.dart';
import '../theme/theme_controller.dart';

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
    ThemeController? theme,
    RelaxedClockSetting? relaxedClock,
    InterceptRun? intercept,
  }) : intercept = intercept ?? InterceptRun(),
       theme = theme ?? ThemeController(),
       relaxedClock = relaxedClock ?? RelaxedClockSetting(),
       consent = consent ?? UmpConsentService(),
       entitlement =
           entitlement ??
           IapEntitlementService(adRemovalProductId: 'ad_removal'),
       ads = ads ?? AdMobAdService(AdMobConfig.test());

  final ConsentService consent;
  final EntitlementService entitlement;
  final AdService ads;

  /// The player's gameplay palette. Not a game-shell service — it lives
  /// here so every screen reaches it the same way.
  final ThemeController theme;

  /// Accessibility: doubles clock ticks when on.
  final RelaxedClockSetting relaxedClock;

  /// Campaign progress through the Intercept transmissions.
  final InterceptRun intercept;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await theme.load();
    await relaxedClock.load();
    await intercept.load();
    await consent.requestConsent();
    await entitlement.restore();

    if (consent.canRequestAds) {
      await ads.initialize();
    }
    ads.setAdFree(entitlement.isAdFree);
    entitlement.adFreeChanges.listen(ads.setAdFree);
  }
}
