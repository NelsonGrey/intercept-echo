# Shift-Register Arcade — Business Requirements

**Document type:** Business Requirements Document (BRD)  
**Version:** 0.1  
**Status:** Proposed / discovery  
**Last updated:** August 11, 2026  
**Owner:** Mark Nelson  
**Working concept:** Shift-register arcade; no final product title selected

Related document: [Technical Requirements](./TECHNICAL_REQUIREMENTS.md)  
Portfolio context: [Requirements Index](../../PORTFOLIO_REQUIREMENTS_INDEX.md)

## 1. Executive summary

The proposed game turns an eight-bit register into a fast, tactile arcade system. Players shift, rotate, and transform visible bit patterns to match incoming targets before a clock completes its cycle. Bits pushed beyond the register boundary become an intentional resource—energy, ammunition, or combo charge—so overflow is a strategic choice rather than merely an error.

The product is intended for short mobile sessions and must be enjoyable as a pattern-transformation game before it is understood as a lesson about binary operations. Its commercial distinction is the combination of live register manipulation, clock pressure, and playable overflow.

## 2. Customer problem and opportunity

Many binary games emphasize conversion exercises, quizzes, or text-based programming. They appeal to learners but can feel like homework to a general player. Mainstream mobile puzzle games offer immediate manipulation and escalating mastery but rarely use authentic computer behavior as the governing rule.

The opportunity is to deliver a one-thumb arcade-puzzle game with a novel visual grammar, very short onboarding, deterministic fairness, and optional technical depth.

## 3. Target audience

### Primary audiences

- Mobile puzzle and score-chasing players who enjoy compact rules and mastery.
- Teen and adult players interested in technology, logic, or retro-computing aesthetics.
- Existing Modulo Squares players who value an authentic mathematical or computational hook.

### Secondary audiences

- Educators and parents seeking a game that builds bit-pattern intuition without a quiz format.
- Programmers who will appreciate accurate terminology, optimization, and hidden depth.

The game must not require prior knowledge of binary, hexadecimal, programming, or bitwise operators.

## 4. Product positioning

**Positioning statement:** For mobile players who enjoy rapid pattern puzzles, this game makes an eight-bit register into a living arcade arena where every shift changes both the target pattern and the resources available for the next move.

### Product principles

1. Pattern recognition precedes numeric interpretation.
2. Every operation must produce immediate, legible audiovisual feedback.
3. Failure must be explainable from the visible state.
4. Advanced technical depth must emerge from play rather than lectures.
5. The game must have its own visual identity and must not imitate terminal-heavy programming games.

## 5. Goals and non-goals

### Goals

- Prove that bit shifting supports a repeatable, satisfying mobile game loop.
- Support sessions of approximately one to five minutes.
- Provide both authored progression and a replayable score mode.
- Establish a second recognizable computer-science game in the portfolio.
- Support the portfolio's standard financial model (matching Modulo Squares): free-to-play with banner and interstitial advertising, plus a one-time purchase that removes all ads.

### Non-goals for MVP

- Teaching a complete binary-number curriculum.
- Requiring players to convert between decimal, binary, and hexadecimal.
- Simulating a real CPU or a specific processor architecture.
- Multiplayer or user-generated levels.
- Consumable currencies, energy timers, forced/blocking ad gates (for example, mandatory rewarded video to continue play), or pay-to-win assistance.

## 6. MVP product scope

The MVP must include:

- A fixed-width eight-bit register presented as eight clearly distinct cells.
- Left shift and right shift as the initial operations.
- Rotate and one carefully introduced mask operation after basic mastery.
- Incoming target patterns and a visible clock or deadline.
- A strategic overflow resource tied directly to bits leaving the register.
- A guided onboarding sequence with no required reading beyond short action prompts.
- At least 40 authored challenges across four mechanic chapters.
- One endless score mode with deterministic difficulty progression.
- Local progression, settings, statistics, and achievement-like milestones.
- Account sign-in (Google or Apple) required before the first challenge; a complete experience thereafter that stays playable offline between sync points, with progress and leaderboard scores syncing to the cloud when connected.
- A global leaderboard for endless-mode score, backed by cloud sync.

Daily challenges, social sharing, additional bit widths, signed arithmetic, and a level editor are post-MVP candidates.

## 7. Business requirements

| ID         | Requirement                                                                                                                       | Priority | Acceptance evidence                                                 |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------- | -------- | ------------------------------------------------------------------- |
| SRA-BR-001 | The game shall provide a complete core loop of inspect, transform, resolve, and reward in no more than 30 seconds of active play. | Must     | Observed prototype loop and usability recording                     |
| SRA-BR-002 | A new player shall be able to complete the first target without knowing binary terminology.                                       | Must     | At least 80% first-task completion in moderated usability tests     |
| SRA-BR-003 | Overflow shall create a meaningful resource or scoring decision and shall not be a cosmetic effect.                               | Must     | Design rules and playtest evidence showing at least two viable uses |
| SRA-BR-004 | Every failed target shall display the operation history and the visible reason for failure.                                       | Must     | Failure-state acceptance test                                       |
| SRA-BR-005 | The MVP shall provide at least 40 authored challenges and one replayable endless mode.                                            | Must     | Content inventory and completed release build                       |
| SRA-BR-006 | Players shall sign in with Google or Apple before the first challenge; the signed-in session shall then support offline play with progress syncing when connectivity returns.           | Must     | Sign-in and offline-sync end-to-end test                            |
| SRA-BR-007 | The commercial model shall be free-to-play with banner and interstitial advertising, plus a one-time purchase that removes all ads. | Must   | Approved pricing and store-product configuration                    |
| SRA-BR-008 | The game shall present technical names only after the corresponding operation has been learned visually.                          | Should   | Tutorial/content review                                             |
| SRA-BR-009 | The visual, audio, UI, code, writing, and level content shall be original or supported by retained license records.               | Must     | Asset provenance register and release audit                         |
| SRA-BR-010 | The final title and icon shall pass store, web, domain, and trademark clearance before public announcement.                       | Must     | Signed clearance checklist                                          |
| SRA-BR-011 | The production decision shall require evidence that players voluntarily replay the gray-box prototype.                            | Must     | Discovery-gate report covering at least 15 target players           |
| SRA-BR-012 | Product analytics shall measure comprehension and retention without requiring personally identifying information.                 | Should   | Approved event catalog and privacy review                           |
| SRA-BR-013 | Core information shall remain understandable without color or audio.                                                              | Must     | Accessibility review and test evidence                              |
| SRA-BR-014 | Store materials shall describe the game as entertainment first and shall not claim guaranteed educational outcomes.               | Must     | Store-listing review                                                |
| SRA-BR-015 | Free players shall see a persistent banner ad on every non-gameplay screen, including the pause overlay, and one interstitial ad when a challenge ends and the player returns to a non-gameplay screen. Ads shall never appear during active target resolution, shall never gate the start of a challenge, and shall never fire on ordinary menu navigation. | Must | Ad-placement review and playtest evidence |
| SRA-BR-016 | Logged-in players shall be able to view a global leaderboard and submit scores from endless-mode score; paid (ad-removal) players retain full access. | Must | Leaderboard integration test |

## 8. Progression and content strategy

### Proposed chapters

1. **Move:** left/right shifts and boundary loss.
2. **Preserve:** rotate operations and planning across multiple targets.
3. **Transform:** one mask operation introduced through visual cause and effect.
4. **Overclock:** mixed operations, shorter cycles, and strategic overflow use.

Each challenge should introduce or combine one idea. Repetition should come from score optimization and execution quality rather than duplicated levels with larger numbers.

## 9. Monetization hypothesis

The game follows the portfolio's standard financial model, matching Modulo Squares: free-to-play with advertising, plus a one-time purchase that removes all ads.

- **Free tier:** the complete game, supported by a persistent banner ad (top of screen) on every non-gameplay screen — menu, chapter/challenge select, settings, results, and the pause overlay — plus one interstitial ad when a challenge ends and the player returns to a non-gameplay screen. Ads never appear during active target resolution, never gate the start of a challenge, and never fire on ordinary menu navigation.
- **Access tiers** (matching Modulo Squares): guest/unauthenticated players get no gameplay entry — sign-in is required before the first challenge. Logged-in free players get full gameplay plus leaderboard participation. Paid logged-in players get full gameplay with ads disabled. This is the default; a future guest mode would need its own local-progress and conversion rules defined before it could ship.
- **Ad removal:** a single one-time in-app purchase disables all ads permanently. This is the only purchase in the MVP.
- **Never monetized:** operations, undo, accessibility features, or any competitive advantage. No consumable currencies or energy timers.
- Cosmetic themes or future content packs may be considered post-launch but are not part of the MVP and are never required to enjoy the free ad-supported experience.

Ad presentation must comply with Google Play and Apple App Store policies and applicable consent requirements (GDPR/UMP, App Tracking Transparency) before any regional rollout.

## 10. Success measures

Discovery and launch targets are hypotheses to validate, not forecasts:

- At least 80% of usability participants complete the first meaningful target unaided.
- At least 60% of prototype participants choose to begin another run.
- Median first-session duration is at least five minutes among players who finish onboarding.
- At least 70% of players who start onboarding complete it.
- Crash-free sessions meet or exceed 99.5% during staged rollout.
- Store rating trends toward 4.3 or higher after a meaningful review sample.
- If a free sample is used, full-unlock conversion is measured separately by acquisition channel.

## 11. Originality and IP gates

Before production approval, the team must:

- Refresh the comparison review for binary, XOR, bit-shifting, and programming puzzle games.
- Maintain a feature-distance matrix covering input, objective, timing, overflow, progression, presentation, and monetization.
- Avoid using competitor screenshots, UI layouts, level structures, characters, text, audio, or code as production references.
- Document the independently developed combination of live shifts, clock cycles, and overflow resources.
- Complete trademark clearance for the final title and visual brand.
- Escalate any credible patent concern after the mechanic is frozen.

## 12. Release decision

The candidate may advance from discovery to production only when the shared portfolio gates pass and the gray-box demonstrates that players enjoy the shifting loop without needing an educational motivation. If pattern matching is enjoyable but overflow is not strategically meaningful, the concept must be revised before production rather than shipping as a conventional binary quiz.
