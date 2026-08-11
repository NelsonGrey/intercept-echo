# Shift-Register Arcade — Technical Requirements

**Document type:** Technical Requirements Document (TRD)  
**Version:** 0.1  
**Status:** Proposed / architecture discovery  
**Last updated:** August 11, 2026  
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
- Ad SDK integration (AdMob): persistent top banner plus interstitials between challenges, gated behind a consent (GDPR/UMP, App Tracking Transparency) flow, never shown during active target resolution.
- Store purchase integration for the single ad-removal entitlement.

### Excluded from MVP

- Required backend, account system, cloud synchronization, multiplayer, live leaderboards, user-generated content, or remote level editor.
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

Authored challenges shall be schema-validated data rather than hard-coded screens. A challenge definition must include:

- Stable challenge ID and content-schema version.
- Initial register and target state.
- Allowed operations and inventory.
- Clock behavior and success conditions.
- Overflow rule and scoring rule.
- Tutorial cues and accessibility descriptions.
- Expected minimum solution length where known.
- Designer test vectors or reference solution.

Content loading must reject invalid bit widths, impossible operation references, duplicate IDs, unsupported schema versions, and challenges without a valid completion path. A solver or bounded reachability check should validate authored challenges during CI.

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
7. Platform services, purchases, advertising, analytics, and crash reporting.

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
| SRA-TR-015 | The ad layer shall be hidden behind an interface with a deterministic fake for tests, shall load consent state before any ad request, and shall suppress all ad units when the ad-removal entitlement is active.                     | SRA-BR-007, SRA-BR-015 |

## 8. Persistence

Local persistence shall include content progress, best scores, tutorial state, settings, aggregate statistics, purchased-entitlement cache, and the most recent interrupted run if restoration is supported.

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
