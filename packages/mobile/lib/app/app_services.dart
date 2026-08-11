import 'package:game_shell/game_shell.dart';

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
  })  : consent = consent ?? UmpConsentService(),
        entitlement =
            entitlement ?? IapEntitlementService(adRemovalProductId: 'ad_removal'),
        ads = ads ?? AdMobAdService(AdMobConfig.test());

  final ConsentService consent;
  final EntitlementService entitlement;
  final AdService ads;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await consent.requestConsent();
    await entitlement.restore();

    if (consent.canRequestAds) {
      await ads.initialize();
    }
    ads.setAdFree(entitlement.isAdFree);
    entitlement.adFreeChanges.listen(ads.setAdFree);
  }
}
