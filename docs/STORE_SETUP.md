# Store setup checklist — Shift-Register Arcade

Neither Google Play nor Apple provide a public API to create a brand-new
app listing, so this part is manual. Everything else (bundle IDs, Firebase
projects, CI) is already wired up to match these values.

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
2. Play Console → Setup → API access → link the `shift-register-arcade-prod` GCP project,
   then create a service account (`google-play-console-service@shift-register-arcade-prod.iam.gserviceaccount.com`)
   matching the pattern used by modulo-squares/vehicle-vitals/wishlist-wizard,
   grant it Release Manager access.
