# Shift-Register Arcade

Flutter + Firebase monorepo, following the same architecture pattern as
Modulo Squares.

Related docs: [Business Requirements](./docs/BUSINESS_REQUIREMENTS.md) ·
[Technical Requirements](./docs/TECHNICAL_REQUIREMENTS.md)

## Status

First playable vertical slice: the register domain engine (`lib/domain/`,
exhaustively tested over all 256 byte values), 7 hand-authored challenges
across the Move/Preserve/Transform chapters (`lib/content/` — not the full
40 SRA-BR-005 calls for yet), and Home/Select/Gameplay/Results screens
wired to `game-shell`'s ad/consent/entitlement services. Verified both with
`flutter test` and by actually running on an iOS Simulator with the real
AdMob service — that live run caught a real crash (see `game-shell`'s
history) that the fakes-only unit tests couldn't have found.

## Layout

- `packages/mobile` — Flutter client (iOS + Android). Depends on [game-shell](https://github.com/NelsonGrey/game-shell) for auth, ads, consent, and the ad-removal entitlement — see that repo before reimplementing any of those.
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

## Deliverables

Each game in this portfolio ships three deliverables:

| Deliverable | Platform | Identifier | Status |
| --- | --- | --- | --- |
| Android app | Google Play | `com.shiftregisterarcade.app.android` | Firebase-registered; Play Console listing not yet created (see [docs/STORE_SETUP.md](docs/STORE_SETUP.md)) |
| iOS app | Apple App Store Connect | `com.shiftregisterarcade.app.ios` | Firebase-registered; ASC app record not yet created (see [docs/STORE_SETUP.md](docs/STORE_SETUP.md)) |
| Website | Firebase Hosting | `shift-register-arcade-{env}.web.app` | **Dev live**; staging/prod configured, not yet deployed |

Website URLs (redeploy with `firebase deploy --only hosting --project <env>`, or run the equivalent Hosting REST API calls if `firebase login` has not been done on this machine):

- Dev: https://shift-register-arcade-dev.web.app &mdash; **live**
- Staging: https://shift-register-arcade-staging.web.app &mdash; not yet deployed
- Prod: https://shift-register-arcade-prod.web.app &mdash; not yet deployed

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

## License

See [LICENSE](LICENSE). Security issues: see [SECURITY.md](SECURITY.md).
