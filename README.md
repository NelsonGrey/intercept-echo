# Intercept Echo

Flutter monorepo. No custom backend: sign-in, leaderboards, achievements,
and cloud save go through each platform's own game-services layer (Game
Center on iOS; Play Games Services on Android, once testing resumes) rather
than a shared Firebase project like the portfolio's earlier games.

Renamed from the working title "Shift-Register Arcade" once
`com.interceptecho.app.ios` was accepted in App Store Connect; "shift
register" now refers only to the underlying register mechanic, not the
product name.

Related docs: [Business Requirements](./docs/BUSINESS_REQUIREMENTS.md) ·
[Technical Requirements](./docs/TECHNICAL_REQUIREMENTS.md)

## Status

The core loop is **Intercept**: register puzzles crack the letters of a
hangman-style coded message, one campaign transmission at a time (no level
list to pick from — see `lib/intercept/`). 12 authored transmissions escalate
from Count (tap cells to a target number) through Shift (reach it by
doubling/halving) to Rotate + Shift once a player has had practice with
Shift alone. Cracking or losing a letter costs/awards signal bars and
points; guessing the whole message early banks a bonus. A `lib/content/`
"Practice" mode with the original Move/Preserve/Transform-style challenges
still exists for ad hoc testing, but Intercept is the game.

Three difficulty levels (Easy/Normal/Hard) trade how many of the register's
place values are shown for a score multiplier. The one-time "Remove Ads"
purchase ($2.99, matching Modulo Squares) is wired end-to-end — entitlement,
ads, and a Settings screen button — pending only the store-side product
creation (see `docs/STORE_SETUP.md`). Settings also links out to the game's
Privacy/Terms/Support pages, hosted on the Nelson Grey site (see below).

Verified both with `flutter test` (register engine exhaustively tested over
all 256 byte values; every Intercept puzzle machine-checked solvable within
its move budget) and by actually running on an iOS Simulator with the real
AdMob service — that live run caught a real crash (see `game-shell`'s
history) that the fakes-only unit tests couldn't have found.

**Not built yet:** the endless score mode and per-platform leaderboard
submission BUSINESS_REQUIREMENTS.md calls for, and gameplay analytics
(SRA-BR-012).

## Layout

- `packages/mobile` — Flutter client (iOS + Android). Depends on [game-shell](https://github.com/NelsonGrey/game-shell) for auth, ads, consent, and the ad-removal entitlement — see that repo before reimplementing any of those.

Bundle/package ID base: `com.interceptecho`

## Deliverables

| Deliverable | Platform | Identifier | Status |
| --- | --- | --- | --- |
| Android app | Google Play | `com.interceptecho.app.android` | Kept buildable; no tester group yet, Play Console listing not yet created (see [docs/STORE_SETUP.md](docs/STORE_SETUP.md)) |
| iOS app | Apple App Store Connect | `com.interceptecho.app.ios` | Bundle ID accepted in App Store Connect; app record not yet created (see [docs/STORE_SETUP.md](docs/STORE_SETUP.md)) |

## Store setup still required manually

Google Play Console and Apple App Store Connect have no public API for
**creating a brand-new app listing** — that first step has to happen in
each console's UI. See `docs/STORE_SETUP.md` for the exact values to enter.

## Legal/support pages

This project has no marketing site of its own (unlike Modulo Squares, which
has a separate site/repo/domain). Privacy/Terms/Support live on the Nelson
Grey site instead, under `games/intercept-echo/` in the
`nelson-grey` repo — see `docs/STORE_SETUP.md` for the URLs.

## Getting started

```bash
cd packages/mobile
flutter pub get
flutter run
```

## License

See [LICENSE](LICENSE). Security issues: see [SECURITY.md](SECURITY.md).
