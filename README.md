# Shift-Register Arcade

Flutter monorepo. No custom backend: sign-in, leaderboards, achievements,
and cloud save go through each platform's own game-services layer (Game
Center on iOS; Play Games Services on Android, once testing resumes) rather
than a shared Firebase project like the portfolio's earlier games.

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

Bundle/package ID base: `com.shiftregisterarcade`

## Deliverables

| Deliverable | Platform | Identifier | Status |
| --- | --- | --- | --- |
| Android app | Google Play | `com.shiftregisterarcade.app.android` | Kept buildable; no tester group yet, Play Console listing not yet created (see [docs/STORE_SETUP.md](docs/STORE_SETUP.md)) |
| iOS app | Apple App Store Connect | `com.shiftregisterarcade.app.ios` | ASC app record not yet created (see [docs/STORE_SETUP.md](docs/STORE_SETUP.md)) |

## Store setup still required manually

Google Play Console and Apple App Store Connect have no public API for
**creating a brand-new app listing** — that first step has to happen in
each console's UI. See `docs/STORE_SETUP.md` for the exact values to enter.

## Getting started

```bash
cd packages/mobile
flutter pub get
flutter run
```

## License

See [LICENSE](LICENSE). Security issues: see [SECURITY.md](SECURITY.md).
