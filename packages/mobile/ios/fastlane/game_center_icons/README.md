# Game Center achievement icons

1024×1024 PNGs for the 5 achievements listed in `docs/STORE_SETUP.md`,
generated from `make_icons.py` (needs `rsvg-convert`) using the game's
real Signal-theme palette (`lib/theme/game_theme.dart`), not invented
colors. Each icon's `.svg` source is kept alongside its `.png` — edit the
SVG (or `make_icons.py` for a shared change) and re-run
`python3 make_icons.py && rsvg-convert -w 1024 -h 1024 -o name.png name.svg`
rather than hand-editing the PNG.

| File | Achievement ID | Upload as |
|---|---|---|
| `first_transmission.png` | `intercept_echo_first_transmission` | its achievement's image |
| `campaign_complete.png` | `intercept_echo_campaign_complete` | its achievement's image |
| `used_rotate.png` | `intercept_echo_used_rotate` | its achievement's image |
| `hard_difficulty.png` | `intercept_echo_hard_difficulty` | its achievement's image |
| `perfect_shift.png` | `intercept_echo_perfect_shift` | its achievement's image |

Upload each PNG on its achievement's page in App Store Connect → Game
Center (drag-and-drop the image field on that achievement's form) — there's
no bulk-upload API for this, it's one at a time in the UI.
