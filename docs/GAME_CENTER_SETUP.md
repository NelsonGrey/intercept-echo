# Game Center Setup (App Store Connect)

The app reports to Game Center by **ID**; nothing is auto-created. These
records must exist in App Store Connect with exactly these IDs
(`packages/mobile/lib/gamecenter/game_center_ids.dart`) before a build that
uses them ships. The same document, in the same shape, exists in Memory
Survival and Modulo Squares.

App Store Connect → app `com.interceptecho.app.ios` → Features → Game Center →
enable Game Center, then create:

## Leaderboard

| Field | Value |
| --- | --- |
| Type | Classic |
| ID | `intercept_echo_total_score` |
| Reference name | Total Score |
| Name (shown to players) | Total Score |
| Description | Your total score across the campaign's decoded transmissions. |
| Score format | Integer |
| Score format suffix | Singular `point`, plural `points` |
| Sort | High to low |
| Score range | 0 – 100000000 |
| Image | `leaderboard-1024.png` (see Art) |

The app submits the player's total campaign score when a transmission is
decoded. Game Center keeps only the best score per player, so resubmitting is
harmless.

## Achievements

Five achievements, 105 points total (Game Center allows 100 achievements and
1,000 points). The triggers are in `lib/intercept/intercept_run.dart`,
`lib/screens/gameplay_screen.dart` and `lib/screens/settings_screen.dart`.
Each needs a title, a pre-earned description (shown while locked: how to earn
it) and an earned description (shown once unlocked: what the player did), an
image and the point value. All are visible (not hidden) and none are
repeatable.

| ID | Title | Pre-earned Description | Earned Description | Pts |
| --- | --- | --- | --- | --- |
| `intercept_echo_first_transmission` | First Contact | Decode the campaign's first transmission. | You decoded the campaign's first transmission. | 10 |
| `intercept_echo_campaign_complete` | Echo Decoded | Decode every transmission in the campaign. | You decoded every transmission in the campaign. | 50 |
| `intercept_echo_used_rotate` | Full Rotation | Crack a letter using Rotate as well as Shift. | You cracked a letter using Rotate as well as Shift. | 10 |
| `intercept_echo_hard_difficulty` | No Safety Net | Switch to Hard difficulty in Settings. | You switched to Hard difficulty. | 10 |
| `intercept_echo_perfect_shift` | Perfect Shift | Solve a Shift-chapter Practice puzzle in par moves. | You solved a Shift-chapter Practice puzzle in par moves. | 25 |

Notes:
- Achievements earned while the player is not connected to Game Center are
  remembered on the device and granted the next time they connect.
- All are one-shot; none use percent-complete (incremental) progress.
- The titles above are proposals; the IDs are what the code depends on.

## Art

Upload-ready art is in `packages/mobile/ios/fastlane/game_center_icons/`: one
1024×1024 PNG per achievement, named `<achievement ID>.png`, plus the
leaderboard image `leaderboard-1024.png`, each with its `.svg` source and the
`make_icons.py` generator. See that folder's README for
regenerating and uploading. Upload each PNG on its achievement's page in App
Store Connect (one at a time; there is no bulk upload).

## Entitlement

`ios/Runner/Runner.entitlements` carries `com.apple.developer.game-center`.
Without it, sign-in and everything downstream fails silently.

Game Center's cloud-saved games (`SaveGame`) are also used, for cross-device
campaign-progress sync. They need no configuration beyond Game Center being
on.

## Behaviour to verify on a real device (TestFlight)

Signed into a Game Center account in iOS Settings:

1. First launch offers to connect to Game Center. **Connect** signs in;
   **Not now** is remembered and the game stays fully playable.
2. Settings → Game Center shows the player's alias, Leaderboard and
   Achievements shortcuts, and Disconnect. Leaderboard and Achievements open
   Game Center's native UI.
3. Decoding the first transmission pops the "First Contact" banner, and a
   score posted from the previous run appears on the leaderboard.
4. Reinstalling on a second device signed into the same Game Center account
   picks up campaign progress.
5. With no Game Center account on the device, the leaderboard shortcut says
   Game Center is unavailable and play is unaffected.
6. Reviewers can play the whole game without connecting.
