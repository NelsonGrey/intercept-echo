import 'dart:io';

import '../shell/shell.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../gamecenter/connection_gated_progress_service.dart';
import '../gamecenter/fake_game_center_progress_service.dart';
import '../gamecenter/game_center_connection.dart';
import '../gamecenter/game_center_progress_service.dart';
import '../gamecenter/games_services_progress_service.dart';
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

/// Real AdMob app/unit IDs for `com.interceptecho.app.ios`, provisioned in
/// the AdMob console (see docs/STORE_SETUP.md). Android IDs stay on
/// Google's shared test values — Android testing hasn't resumed yet (see
/// README status) — swap those in once an Android AdMob app exists.
const _interceptEchoAdMobConfig = AdMobConfig(
  androidAppId: 'ca-app-pub-3940256099942544~3347511713',
  androidBannerId: 'ca-app-pub-3940256099942544/6300978111',
  androidInterstitialId: 'ca-app-pub-3940256099942544/1033173712',
  iosAppId: 'ca-app-pub-5198775482699756~2223602919',
  iosBannerId: 'ca-app-pub-5198775482699756/9715080120',
  iosInterstitialId: 'ca-app-pub-5198775482699756/6596204603',
);

/// The app's services (ads, consent, purchases, Game Center, settings),
/// wired in dependency order by [initialize].
class AppServices {
  AppServices({
    ConsentService? consent,
    EntitlementService? entitlement,
    AdService? ads,
    PlatformGameAuthService? auth,
    GameCenterProgressService? progress,
    GameCenterConnection? connection,
    ThemeController? theme,
    RelaxedClockSetting? relaxedClock,
    InterceptRun? intercept,
    DifficultySetting? difficulty,
    UrlOpener? openUrl,
  }) : difficulty = difficulty ?? DifficultySetting(),
       theme = theme ?? ThemeController(),
       relaxedClock = relaxedClock ?? RelaxedClockSetting(),
       openUrl = openUrl ?? _defaultOpenUrl,
       consent = consent ?? UmpConsentService(),
       entitlement =
           entitlement ??
           IapEntitlementService(adRemovalProductId: 'intercept_echo_remove_ads'),
       ads = ads ?? AdMobAdService(_interceptEchoAdMobConfig),
       _injectedIntercept = intercept,
       auth = auth ?? _defaultAuth(),
       progressBackend = progress ?? _defaultProgress() {
    this.connection =
        connection ??
        GameCenterConnection(auth: this.auth, supported: _gcSupported);
    this.progress = ConnectionGatedProgressService(
      progressBackend,
      this.connection,
    );
    this.connection.onConnected = _onGameCenterConnected;
  }

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

  static bool get _gcSupported => Platform.isIOS || Platform.isMacOS;

  /// Whether the player has opted in to Game Center, and whether it's live.
  /// Nothing talks to Game Center until they connect.
  late final GameCenterConnection connection;

  /// The real (or fake) Game Center calls, same iOS/macOS-only story as
  /// [auth]. Always reach them through [progress], which honors the
  /// player's choice.
  final GameCenterProgressService progressBackend;

  /// Leaderboard/achievements/cloud save, active only while [connection] is
  /// connected — see [GameCenterProgressService].
  late final ConnectionGatedProgressService progress;

  static GameCenterProgressService _defaultProgress() =>
      (Platform.isIOS || Platform.isMacOS)
      ? GamesServicesProgressService()
      : FakeGameCenterProgressService();

  /// The player's gameplay palette. Not a platform service — it lives
  /// here so every screen reaches it the same way.
  final ThemeController theme;

  /// Accessibility: doubles clock ticks when on.
  final RelaxedClockSetting relaxedClock;

  /// Easy shows cell place values; Hard hides them.
  final DifficultySetting difficulty;

  final InterceptRun? _injectedIntercept;

  /// Campaign progress through the Intercept transmissions.
  late final InterceptRun intercept =
      _injectedIntercept ?? InterceptRun(progress: progress);

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

    // Only reconnects a player who already opted in; a failed sign-in (e.g.
    // no Game Center account on this device) lands in
    // GameCenterStatus.unavailable and never blocks the app from starting.
    await connection.load();

    if (consent.canRequestAds) {
      await ads.initialize();
    }
    ads.setAdFree(entitlement.isAdFree);
    entitlement.adFreeChanges.listen(ads.setAdFree);
  }

  /// After each Game Center sign-in: grant achievements earned while
  /// disconnected, then merge the cloud save and push the current score.
  Future<void> _onGameCenterConnected() async {
    await progress.flushEarned();
    await intercept.syncWithGameCenter();
  }
}
