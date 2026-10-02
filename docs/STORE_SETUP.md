# Store setup checklist — Intercept Echo

Neither Google Play nor Apple provide a public API to create a brand-new
app listing, so this part is manual. Everything else (bundle IDs, CI) is
already wired up to match these values. This project has no backend project
to link — sign-in, leaderboards, and achievements go through Game Center
(iOS) and Play Games Services (Android) directly.

## Legal/support URLs

Intercept Echo has no marketing site of its own (unlike Modulo
Squares, which has a separate site/repo/domain). Its Privacy/Terms/Support
pages live on the Nelson Grey site instead, under `games/intercept-echo/`
in the `nelson-grey` repo:

- Privacy: <https://nelsongrey.com/games/intercept-echo/privacy>
- Terms: <https://nelsongrey.com/games/intercept-echo/terms>
- Support: <https://nelsongrey.com/games/intercept-echo/support>

(A 301 redirect from the old `/games/shift-register-arcade/...` slug is in
place in `nelson-grey`'s `firebase.json`, in case it was already entered
anywhere before the rename.)

Use these for App Store Connect's Privacy Policy URL and Support URL, and
Play Console's Privacy Policy URL, below.

## Apple App Store Connect

1. Developer portal → Identifiers → register bundle ID: `com.interceptecho.app.ios` — **done**, accepted in App Store Connect
2. App Store Connect → Apps → **+** → New App
   - Platform: iOS
   - Name: Intercept Echo (check availability; store name is portfolio-wide unique)
   - Primary language: English (U.S.)
   - Bundle ID: `com.interceptecho.app.ios`
   - SKU: `intercept-echo-ios`
   - App Privacy → Privacy Policy URL: see Legal/support URLs above
   - App Information → Support URL: see Legal/support URLs above
3. App Store Connect → In-App Purchases → **+** → Non-Consumable (matches
   Modulo Squares' ad-removal product)
   - Reference name: Remove Ads
   - Product ID: `intercept_echo_remove_ads` (must match `AppServices`' `adRemovalProductId`
     in `lib/app/app_services.dart`)
   - Price: Tier 3 ($2.99)
   - Validate on a real device in a TestFlight build: tapping "Remove Ads —
     $2.99" in Settings shows the StoreKit purchase sheet at the right price.
4. AdMob console → app `com.interceptecho.app.ios` — **done**, real app/unit
   IDs provisioned and wired into `lib/app/app_services.dart` and
   `ios/Runner/Info.plist`'s `GADApplicationIdentifier`
   (`ca-app-pub-5198775482699756~2223602919`; banner
   `.../9715080120`, interstitial `.../6596204603`). Still open:
   - **UMP consent message**: configure a GDPR/consent message for this
     AdMob app in AdMob → Privacy & messaging — the code already calls
     Google's UMP SDK before ads load, but the form has nothing to show
     until a message is defined there.
   - **app-ads.txt**: publish `google.com, pub-5198775482699756, DIRECT,
     f08c47fec0942fa0` at `https://nelsongrey.com/app-ads.txt` (that's the
     `nelson-grey` site repo, not this one — add it alongside the other
     three apps' entries).
   - Android stays on Google's shared test IDs
     (`AdMobConfig`'s android* fields) until an Android AdMob app exists.
5. App Store Connect → Features → Game Center → app `com.interceptecho.app.ios`
   — enable Game Center, then create these records (IDs must match
   `lib/gamecenter/game_center_progress_service.dart`'s `GameCenterIds`
   exactly — the code references them by ID, nothing here is auto-created):
   - **Leaderboard** (Classic, higher score is better): ID
     `intercept_echo_total_score`
   - **Achievements** (five, no ordering requirement):
     - `intercept_echo_first_transmission` — "First Contact" or similar:
       decode the campaign's first transmission
     - `intercept_echo_campaign_complete` — decode every transmission in
       the campaign
     - `intercept_echo_used_rotate` — crack a letter using Rotate as well
       as Shift
     - `intercept_echo_hard_difficulty` — switch to Hard difficulty in
       Settings
     - `intercept_echo_perfect_shift` — solve a Shift-chapter Practice
       puzzle in par moves (see `PracticeScoring`)
   - The game only signs in after the player opts in (first-run prompt,
    home-screen badge, or Settings > Game Center). Reviewers can play the
    whole game without it.
  - Also enables Game Center's cloud-saved games (`SaveGame`), used for
     cross-device campaign-progress sync — no separate ASC configuration
     for that beyond Game Center being on.
   - The Xcode project's Game Center *capability* (the
     `com.apple.developer.game-center` entitlement) was previously
     missing entirely — `ios/Runner/Runner.entitlements` now has it. Without
     it, `GameCenterAuthService.signIn()` (and everything downstream of it)
     was failing silently every time, caught by the empty `catch` in
     `AppServices.initialize()`.
   - Validate all of this on a real device signed into Game Center in a
     TestFlight build: Settings → Leaderboard/Achievements should open
     Game Center's native UI: cracking a letter should eventually pop the
     achievement banners; reinstalling the app on a second device signed
     into the same Game Center account should pick up campaign progress.

## Google Play Console

1. Play Console → Create app
   - App name: Intercept Echo
   - Package name: `com.interceptecho.app.android` (must match exactly, permanent)
   - Default language, Free/Paid per BUSINESS_REQUIREMENTS.md monetization section
   - Store presence → Main store listing → Privacy Policy URL: see Legal/support URLs above
2. Play Console → Play Games Services → set up a new Play Games Services
   project for `com.interceptecho.app.android`, once Android testing
   resumes (see README status).
3. Play Console → Monetize → Products → In-app products → **+**
   - Product ID: `intercept_echo_remove_ads` (must match the iOS product ID above)
   - Price: $2.99
   - Once Android testing resumes: validate the purchase flow the same way
     as iOS, on a real device with a licensed test account.

## iOS release pipeline

`.github/workflows/ios-mobile-release.yml` builds, signs, and uploads via
`packages/mobile/ios/fastlane` (`workflow_dispatch`, same pattern as
vehicle-vitals and wishlist-wizard): automatic code signing authenticated
by an App Store Connect API key (`-allowProvisioningUpdates`), not a
git-based cert store. Lanes: `build_only`, `beta` (TestFlight),
`build_appstore`, `push_appstore_metadata`, `submit_appstore_for_review`
(gated — see below).

Before the first run, add these to the repo's Settings → Secrets and
variables → Actions (same Apple Developer team as the other three apps,
so these are the same values already used for vehicle-vitals/wishlist-wizard,
just re-entered here — GitHub secrets aren't shared across repos):

- `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`,
  `APP_STORE_CONNECT_KEY` (the `.p8` key content)
- `FASTLANE_APPLE_ID`, `FASTLANE_ITC_TEAM_ID`, `FASTLANE_TEAM_ID`

Two GitHub Environments gate the workflow (already created:
`ios-testflight`, ungated; `ios-appstore`, meant to require a reviewer
before `appstore_submit` runs — **the required-reviewer rule itself
couldn't be added via the API**: this repo is private, and GitHub only
allows required-reviewer protection rules on private repos on a paid Team/
Enterprise plan. Add it manually once the org is on that plan (Settings →
Environments → ios-appstore → required reviewers), or make the repo
public. Until then, `appstore_submit` runs unattended.

`fastlane/metadata/en-US/` holds the store listing text (name, keywords,
description); there's no `fastlane/screenshots/` yet — add real device
screenshots there before running `push_appstore_metadata` or
`appstore_submit` for the first time (`deliver` skips screenshots only
while that directory doesn't exist).

## Rename complete

The Intercept Echo rename is done end to end: bundle IDs, package name,
class names, and docs in this repo; the GitHub repo itself
(`NelsonGrey/shift-register` → `NelsonGrey/intercept-echo`, with GitHub's
usual redirect from the old URL); and the Nelson Grey site's legal pages
(`games/shift-register-arcade/` → `games/intercept-echo/`, with an explicit
301 redirect as a safety net). If you cloned this repo before the rename,
update your remote: `git remote set-url origin
https://github.com/NelsonGrey/intercept-echo.git`.
