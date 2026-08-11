# Shift-Register Arcade

Flutter + Firebase monorepo, following the same architecture pattern as
Modulo Squares.

Related docs: [Business Requirements](./BUSINESS_REQUIREMENTS.md) ·
[Technical Requirements](./TECHNICAL_REQUIREMENTS.md)

## Layout

- `packages/mobile` — Flutter client (iOS + Android)
- `packages/functions` — Firebase Cloud Functions (Node 22 / TypeScript)
- `packages/firestore-rules` — Firestore security rules
- `packages/web` — landing page (Firebase Hosting)
- `firebase-config/` — downloaded per-environment Firebase config files (gitignored)

## Firebase projects

| Env     | Project ID              |
| ------- | ------------------------ |
| dev     | `shift-register-arcade-dev`     |
| staging | `shift-register-arcade-staging` |
| prod    | `shift-register-arcade-prod`    |

Bundle/package ID base: `com.shiftregisterarcade`

## Store setup still required manually

Google Play Console and Apple App Store Connect have no public API for
**creating a brand-new app listing** — that first step has to happen in
each console's UI. See `docs/STORE_SETUP.md` for the exact values to enter.

## Getting started

```bash
cd packages/mobile
cp ../../firebase-config/google-services.dev.json android/app/google-services.json
cp ../../firebase-config/GoogleService-Info.dev.plist ios/Runner/GoogleService-Info.plist
flutter pub get
flutter run
```
