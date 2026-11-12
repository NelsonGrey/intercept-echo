# Asset Manifest — Intercept Echo

Launch-ready imagery for the iOS release of Intercept Echo. Every gameplay image uses the native iPhone simulator capture from September 30, 2026. No game UI was invented or AI-generated.

## Upload-ready locations

- App Store: `packages/mobile/ios/fastlane/screenshots/en-US/` and the self-contained mirror at `assets/store/app-store/6.5-inch-1242x2688/`
- General banner: `assets/headers/general/`
- Platform headers: `assets/headers/{x,facebook,linkedin,bluesky,youtube}/`
- Campaign posts: `assets/social/campaigns/<campaign>/`
- Shared profile artwork: `assets/identity/`
- Unmodified native capture sources: `assets/store/app-store/raw/`
- Remove Ads in-app purchase image: `assets/store/app-store/in-app-purchase/remove-ads-1024x1024.png`
- Settings purchase evidence: `assets/store/app-store/settings-purchase/` contains the native 1206 x 2622 iPhone capture and a 1242 x 2688 upload derivative.

## App Store sequence

The six 1242 x 2688 PNGs target the 6.5-inch App Store slot shown by App Store Connect and are ordered as a product story:

1. Crack the transmission
2. Master eight bits
3. Solve efficiently
4. Read the signal
5. Take the risk
6. Chase the next echo

They are opaque RGB PNGs and are already installed in Fastlane's English (U.S.) screenshot directory. Keep the numerical filename prefixes when uploading.

## Social campaign set

Each of the four campaign concepts is provided in four reusable ratios:

- 1080 x 1080 square
- 1080 x 1350 portrait feed
- 1080 x 1920 story / reel cover
- 1200 x 675 landscape link or video card

Campaigns:

- `every-bit`: broad launch / core mechanic
- `crack-message`: campaign mystery
- `guess-early`: risk-and-reward hook
- `exact-logic`: deterministic puzzle positioning

## Publication notes

- The iOS App Store destination currently used by the website is `https://apps.apple.com/app/id6816505842`.
- Do not imply Android availability. Android is intentionally absent from this launch package.
- The transparent mark is a design source. Prefer the opaque 1024 x 1024 profile icon for direct platform upload.
- The Remove Ads promotional image is a flattened 1024 x 1024 RGB PNG with square corners, suitable for the `intercept_echo_remove_ads` in-app purchase record.
- The Settings purchase screenshot uses deterministic fake services to display the unowned entitlement without contacting StoreKit or AdMob. It documents the purchase UI; it is not evidence that a live transaction completed.
- Preview headers in each platform's own crop tool before publishing. YouTube's key text is constrained to the central 1546-pixel safe width, but device and TV crops still vary.
- The source capture is simulator-based and deterministic. Replace only if a later shipping build materially changes visible UI.

## Rebuild

From the repository root:

```sh
python3 marketing/tools/build_go_to_market_assets.py
```

The builder reads the existing native captures and the brand artwork from the Nelson Grey website checkout. `ASSET_MANIFEST.csv` records dimensions, modes, byte sizes, and SHA-256 hashes.
