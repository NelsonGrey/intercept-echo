# Intercept Echo gameplay capture

Captured from the iPhone 17 Pro simulator on 2026-09-30.

## Deliverables

- `intercept-echo-gameplay-tour.mp4` — complete 25.57-second loop from the home screen through cracking `S`, guessing `SIGNAL FOUND`, viewing the transmission result, and opening transmission 2.
- `../store/app-store/raw/` — eight native 1206×2622 RGB PNGs covering the principal screens and gameplay states.

The final video is silent H.264/yuv420p at 1206×2622 and constant 30 fps. The capture uses deterministic local test services in ad-free mode; it does not contact ad, purchase, or Game Center services.

## Reproduce

With an iOS simulator booted, run:

```sh
flutter test integration_test/gameplay_capture_test.dart -d <simulator-udid>
```

The integration test drives the same complete gameplay loop used for this capture.
