# Shift-Register Arcade — Technical Requirements

**Document type:** Technical Requirements Document (TRD)  
**Version:** 0.2 — updated for the Intercept core-loop pivot (see §4.2)  
**Status:** Proposed / architecture discovery  
**Last updated:** September 26, 2026  
**Owner:** Mark Nelson

Related document: [Business Requirements](./BUSINESS_REQUIREMENTS.md)  
Portfolio context: [Requirements Index](../../PORTFOLIO_REQUIREMENTS_INDEX.md)

## 1. Purpose

This document defines the technical requirements for a deterministic mobile arcade-puzzle game centered on an eight-bit shift register. It describes the simulation, content model, input, rendering, persistence, testing, telemetry, accessibility, and release constraints required to satisfy the business requirements.

The document authorizes neither a specific framework nor production implementation. A short architecture decision record must choose the client stack after gray-box validation, with reuse of the proven Modulo Squares mobile foundation considered where appropriate.

## 2. System scope

### MVP components

- Cross-platform iOS and Android client.
- Deterministic register simulation independent of rendering frame rate.
- Data-driven authored challenge loader.
- Endless-mode generator with reproducible seeds.
- Tutorial and progression state machine.
- Local settings, save data, and aggregate statistics.
- Audio, haptic, animation, and accessibility presentation layers.
- Privacy-minimized analytics and crash reporting behind build-time configuration.
- Ad SDK integration (AdMob): persistent top banner on every non-gameplay screen (including pause), plus one interstitial per completed/lost Intercept transmission (not per letter) on the way back to a non-gameplay screen, gated behind a consent (GDPR/UMP, App Tracking Transparency) flow. Never shown during active target resolution, never gating the start of a puzzle, never on ordinary menu navigation.
- Platform game-services sign-in (Game Center on iOS; Play Games Services on Android, once testing resumes) gating access to gameplay, matching the portfolio's account-required access model. No custom backend.
- Local persistence for progress, statistics, and settings, with the platform's own leaderboard/achievement services holding the account-scoped online state.
- Per-platform leaderboard for endless-mode score, submitted through Game Center (iOS) / Play Games Services (Android) rather than a custom server.
- Store purchase integration for the single ad-removal entitlement.

### Excluded from MVP

- Multiplayer, user-generated content, or remote level editor.
- Arbitrary-width integers, real processor emulation, programmable instruction sequences, or executable user code.

## 3. Core simulation

### 3.1 Register state

The authoritative game state shall contain at minimum:

```text
RegisterState
  width: 8
  bits: unsigned 8-bit value
  targetBits: unsigned 8-bit value
  allowedOperations: ordered set
  operationInventory: per-operation remaining uses or unlimited
  overflowBuffer: ordered bits and/or derived energy count
  cycleRemaining: simulation ticks
  scoreState: combo, multiplier, objective progress
  operationHistory: append-only entries for current objective
  seed: deterministic random seed where applicable
```

The bit value is authoritative; individual visual cells are derived presentation. Serialization must define bit order explicitly, with index `0` assigned consistently to the least- or most-significant bit throughout content, telemetry, tests, and accessibility labels.

### 3.2 Operations

The MVP operation engine shall support:

- Logical left shift with zero fill and captured outgoing bit.
- Logical right shift with zero fill and captured outgoing bit.
- Rotate left and rotate right when unlocked.
- One configurable bit-mask operation selected during discovery from AND, OR, or XOR.

Every operation must be a pure deterministic state transition. Visual effects may not alter timing or results. Operation definitions must specify outgoing bits, inserted bits, overflow rewards, inventory cost, scoring effect, and invalid-state behavior.

### 3.3 Objective resolution

- A target succeeds only when the register matches the target according to the challenge's declared comparison rule.
- Resolution must occur on a documented simulation boundary to prevent input-order ambiguity.
- The simulation shall retain the last operations needed to reconstruct every success or failure.
- Pausing, backgrounding, interruption, or a dropped render frame shall not consume unobserved real-time operations.
- Time-limited modes shall use a monotonic clock and defined pause policy.

## 4. Content model

There are two content sources, both funneling into the same `Challenge` shape (`lib/content/challenge.dart`) the simulation and screens consume:

### 4.1 Practice challenges

A small hand-authored set (`ChallengeRepository`) for ad hoc testing outside the campaign. A challenge definition must include:

- Stable challenge ID and content-schema version.
- Initial register and target state.
- Allowed operations and inventory.
- Clock behavior and success conditions.
- Overflow rule and scoring rule.
- Tutorial cues and accessibility descriptions.
- Expected minimum solution length where known.
- Designer test vectors or reference solution.

These are still Dart literals rather than schema-validated external data (the schema-validated-data vision above is not yet built), so content loading has no format to reject invalid entries against yet; a solver-based test (`challenge_solvability_test.dart`) instead checks every entry is solvable within its budget, and this must keep running in CI.

### 4.2 Intercept transmissions

The campaign's actual content unit. A `Transmission` (`lib/intercept/transmission.dart`) is authored data — a phrase, a cipher key, a puzzle kind (Count/Shift/Rotate+Shift/mixed/advanced), and whether it's clocked — but its per-letter `Challenge`s are not authored directly: `PuzzleFactory` generates one deterministically from the transmission, the letter, and a retry-attempt counter, choosing a start state whose shortest solution (via the same BFS solver used for reachability checks) sits in a difficulty-appropriate move-count band. This means Intercept content validation is a property to test across every transmission and letter — every generated puzzle must be solvable within its move budget — rather than a fixed list to schema-check; `puzzle_factory_solvability_test.dart` is this check and must keep running in CI alongside 4.1's.

## 5. Input and presentation

- Primary play shall support one-thumb taps and horizontal swipes without requiring precision smaller than platform accessibility guidance.
- Every swipe action shall have an equivalent tap control for motor accessibility and deterministic automated testing.
- Input buffering shall define whether more than one operation may be queued per simulation tick.
- The register, target, direction, outgoing bit, and inserted zero shall remain distinguishable during animation.
- Color shall reinforce but never solely encode zero/one, current/target, success/failure, or operation availability.
- Audio and haptic feedback shall be independently adjustable and shall not be required to play.
- Reduced-motion mode shall replace large translations, flashes, and camera motion with concise state transitions.

## 6. Architecture requirements

The client shall separate:

1. Immutable or controlled mutable domain state.
2. Deterministic simulation and scoring.
3. Content definitions and validation.
4. Input translation.
5. Rendering, animation, audio, and haptics.
6. Persistence and migrations.
7. Platform services, purchases, advertising, authentication, cloud sync, analytics, and crash reporting.

The simulation must be runnable in headless unit tests. Platform integrations must be hidden behind interfaces so test builds can use deterministic fakes.

## 7. Technical requirements

| ID         | Requirement                                                                                                                                           | Maps to                |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------- |
| SRA-TR-001 | The simulation shall produce identical state and score for identical initial state, seed, tick sequence, and input sequence.                          | SRA-BR-001, SRA-BR-004 |
| SRA-TR-002 | All register operations shall be covered by exhaustive tests across all 256 eight-bit values.                                                         | SRA-BR-001, SRA-BR-004 |
| SRA-TR-003 | The engine shall record a replayable operation history for the current objective.                                                                     | SRA-BR-004             |
| SRA-TR-004 | Authored challenges shall be schema validated and completion checked before packaging.                                                                | SRA-BR-005             |
| SRA-TR-005 | Endless runs shall be reproducible from a stored seed and ruleset version.                                                                            | SRA-BR-005             |
| SRA-TR-006 | Core play and all purchased content shall remain available offline after platform entitlement caching.                                                | SRA-BR-006, SRA-BR-007 |
| SRA-TR-007 | Save data shall use versioned migrations and atomic replacement to prevent partial-write corruption.                                                  | SRA-BR-005             |
| SRA-TR-008 | The game shall support screen-reader labels, non-color bit differentiation, reduced motion, adjustable audio/haptics, and tap alternatives to swipes. | SRA-BR-013             |
| SRA-TR-009 | Analytics payloads shall exclude raw advertising identifiers, contacts, precise location, and user-entered personal data.                             | SRA-BR-012             |
| SRA-TR-010 | The renderer shall sustain 60 frames per second at the defined baseline devices while simulation results remain independent of frame rate.            | SRA-BR-001             |
| SRA-TR-011 | Cold launch to an interactive local menu shall target three seconds or less on baseline devices.                                                      | SRA-BR-001             |
| SRA-TR-012 | All third-party code and assets shall be recorded with version, source, license, and intended use.                                                    | SRA-BR-009             |
| SRA-TR-013 | Purchase failure, cancellation, pending status, restore, and offline entitlement states shall be handled without losing progression.                  | SRA-BR-007             |
| SRA-TR-014 | Builds shall expose content and ruleset versions in diagnostics without exposing secrets or personal data.                                            | SRA-BR-004, SRA-BR-012 |
| SRA-TR-015 | The ad layer shall be hidden behind an interface with a deterministic fake for tests, shall load consent state before any ad request, shall suppress all ad units when the ad-removal entitlement is active, and shall enforce a minimum interval between interstitials so accidental extra calls cannot spam ads.                     | SRA-BR-007, SRA-BR-015 |
| SRA-TR-016 | Gameplay shall be gated behind platform game-services sign-in (Game Center on iOS; Play Games Services on Android, once testing resumes); unauthenticated users shall see only the sign-in flow. | SRA-BR-006 |
| SRA-TR-017 | Endless-mode scores shall submit to the platform's own leaderboard service (Game Center/Play Games Services), with local caching for offline play and no custom backend involved. | SRA-BR-016 |

## 8. Persistence

Local persistence shall include content progress, best scores, tutorial state, settings, aggregate statistics, purchased-entitlement cache, and the most recent interrupted run if restoration is supported. There is no custom backend or cross-device sync of this local state.

Endless-mode scores submit directly to the platform's leaderboard service (Game Center on iOS; Play Games Services on Android, once testing resumes), which owns score storage, ranking, and any cross-device consistency on that platform. Leaderboards are per-platform and not unified across iOS and Android. Local caching keeps score submission resilient to offline play; a cached score submits on the next successful connection.

The game shall never silently reset progress after a schema change. Corrupt data handling must retain a recoverable backup where feasible, start from safe defaults, and present an understandable recovery message.

## 9. Telemetry

The minimum event catalog should include:

- Tutorial step started/completed/abandoned.
- Challenge started/completed/failed/retried.
- Operation used, expressed as an enum without a full raw interaction trace by default.
- Failure reason category.
- Endless run start/end and score band.
- Purchase screen viewed and platform purchase outcome if applicable.
- Ad impression and click events (aggregate SDK-reported events only, no custom cross-app tracking).
- Sign-in method and outcome (Game Center/Play Games Services).
- Leaderboard view and submission events.
- Accessibility setting enabled.

Analytics must be disableable by distribution or consent policy. Gameplay must not depend on successful event delivery.

## 10. Testing strategy

- Exhaustive unit tests for every operation over every eight-bit input.
- Property tests for rotate reversibility and shift invariants.
- Golden tests for register/target legibility at supported text scales and themes.
- Content validation and reference-solution tests.
- Replay determinism tests across supported platforms.
- Integration tests for pause, resume, interruption, save migration, purchase restore, and offline launch.
- Ad-layer tests: consent flow, ad load failure/fallback, and entitlement-based ad suppression using the deterministic fake.
- Integration tests for platform sign-in flow and leaderboard submission, using each platform's deterministic fake.
- Accessibility tests for screen readers, switch/tap-only input, reduced motion, contrast, and audio-disabled play.
- Device tests across a documented low-, mid-, and high-performance matrix for iOS and Android.

## 11. Release gates

Production release requires:

- Zero known severity-one gameplay, purchase, data-loss, or accessibility blockers.
- Exhaustive operation tests and all packaged-content validations passing.
- No unexplained replay divergence between supported platforms.
- Crash-free staged rollout meeting the business target.
- Performance targets met on baseline devices.
- Completed dependency and asset-license inventory.
- Privacy disclosures reconciled with the final SDK and telemetry behavior.
- Store purchase and restore flows verified with store-distributed test builds for the ad-removal entitlement.
- Ad content and placement reviewed against Google Play and Apple App Store ad policies, with consent flow verified for GDPR/UMP and App Tracking Transparency.
