# Store setup checklist — Shift-Register Arcade

Neither Google Play nor Apple provide a public API to create a brand-new
app listing, so this part is manual. Everything else (bundle IDs, CI) is
already wired up to match these values. This project has no backend project
to link — sign-in, leaderboards, and achievements go through Game Center
(iOS) and Play Games Services (Android) directly.

## Legal/support URLs

Shift-Register Arcade has no marketing site of its own (unlike Modulo
Squares, which has a separate site/repo/domain). Its Privacy/Terms/Support
pages live on the Nelson Grey site instead, under `games/shift-register-arcade/`
in the `nelson-grey` repo:

- Privacy: <https://nelsongrey.com/games/shift-register-arcade/privacy>
- Terms: <https://nelsongrey.com/games/shift-register-arcade/terms>
- Support: <https://nelsongrey.com/games/shift-register-arcade/support>

Use these for App Store Connect's Privacy Policy URL and Support URL, and
Play Console's Privacy Policy URL, below.

## Apple App Store Connect

1. Developer portal → Identifiers → register bundle ID: `com.shiftregisterarcade.app.ios`
2. App Store Connect → Apps → **+** → New App
   - Platform: iOS
   - Name: Shift-Register Arcade (check availability; store name is portfolio-wide unique)
   - Primary language: English (U.S.)
   - Bundle ID: `com.shiftregisterarcade.app.ios`
   - SKU: `shift-register-arcade-ios`
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
   - App name: Shift-Register Arcade
   - Package name: `com.shiftregisterarcade.app.android` (must match exactly, permanent)
   - Default language, Free/Paid per BUSINESS_REQUIREMENTS.md monetization section
   - Store presence → Main store listing → Privacy Policy URL: see Legal/support URLs above
2. Play Console → Play Games Services → set up a new Play Games Services
   project for `com.shiftregisterarcade.app.android`, once Android testing
   resumes (see README status).
3. Play Console → Monetize → Products → In-app products → **+**
   - Product ID: `ad_removal` (must match the iOS product ID above)
   - Price: $2.99
   - Once Android testing resumes: validate the purchase flow the same way
     as iOS, on a real device with a licensed test account.
