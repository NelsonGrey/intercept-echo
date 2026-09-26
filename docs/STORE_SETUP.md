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
   - Product ID: `ad_removal` (must match `AppServices`' `adRemovalProductId`
     in `lib/app/app_services.dart`)
   - Price: Tier 3 ($2.99)
   - Validate on a real device in a TestFlight build: tapping "Remove Ads —
     $2.99" in Settings shows the StoreKit purchase sheet at the right price.

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
   - Product ID: `ad_removal` (must match the iOS product ID above)
   - Price: $2.99
   - Once Android testing resumes: validate the purchase flow the same way
     as iOS, on a real device with a licensed test account.

## Rename complete

The Intercept Echo rename is done end to end: bundle IDs, package name,
class names, and docs in this repo; the GitHub repo itself
(`NelsonGrey/shift-register` → `NelsonGrey/intercept-echo`, with GitHub's
usual redirect from the old URL); and the Nelson Grey site's legal pages
(`games/shift-register-arcade/` → `games/intercept-echo/`, with an explicit
301 redirect as a safety net). If you cloned this repo before the rename,
update your remote: `git remote set-url origin
https://github.com/NelsonGrey/intercept-echo.git`.
