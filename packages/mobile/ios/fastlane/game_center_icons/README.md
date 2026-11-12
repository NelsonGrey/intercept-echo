# Game Center achievement icons

1024×1024 PNGs, one per achievement in `docs/GAME_CENTER_SETUP.md`, named
`<achievement ID>.png`. Each `.svg` is the source; `make_icons.py` generates them from the game's
real Signal-theme palette (`lib/theme/game_theme.dart`). To change one, edit
the script, then `python3 make_icons.py` and
`rsvg-convert -w 1024 -h 1024 -o NAME.png NAME.svg` (needs `rsvg-convert`);
do not hand-edit the PNG.

Upload each PNG on its achievement's page in App Store Connect → Features →
Game Center (drag it onto the image field). There is no bulk-upload API; it is
one at a time in the UI.

| File | Achievement |
| --- | --- |
| `intercept_echo_first_transmission.png` | First Contact |
| `intercept_echo_campaign_complete.png` | Echo Decoded |
| `intercept_echo_used_rotate.png` | Full Rotation |
| `intercept_echo_hard_difficulty.png` | No Safety Net |
| `intercept_echo_perfect_shift.png` | Perfect Shift |
| `leaderboard-1024.png` | Leaderboard image (1024×1024, no text) |
