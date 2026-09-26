# Store setup checklist — Shift-Register Arcade

Neither Google Play nor Apple provide a public API to create a brand-new
app listing, so this part is manual. Everything else (bundle IDs, CI) is
already wired up to match these values. This project has no backend project
to link — sign-in, leaderboards, and achievements go through Game Center
(iOS) and Play Games Services (Android) directly.

## Apple App Store Connect

1. Developer portal → Identifiers → register bundle ID: `com.shiftregisterarcade.app.ios`
2. App Store Connect → Apps → **+** → New App
   - Platform: iOS
   - Name: Shift-Register Arcade (check availability; store name is portfolio-wide unique)
   - Primary language: English (U.S.)
   - Bundle ID: `com.shiftregisterarcade.app.ios`
   - SKU: `shift-register-arcade-ios`

## Google Play Console

1. Play Console → Create app
   - App name: Shift-Register Arcade
   - Package name: `com.shiftregisterarcade.app.android` (must match exactly, permanent)
   - Default language, Free/Paid per BUSINESS_REQUIREMENTS.md monetization section
2. Play Console → Play Games Services → set up a new Play Games Services
   project for `com.shiftregisterarcade.app.android`, once Android testing
   resumes (see README status).
