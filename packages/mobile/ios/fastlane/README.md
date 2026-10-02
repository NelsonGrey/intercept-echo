fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios build_only

```sh
[bundle exec] fastlane ios build_only
```

Build the Flutter iOS app, unsigned — sanity check only

### ios build_appstore

```sh
[bundle exec] fastlane ios build_appstore
```

Build and sign iOS app for App Store distribution (build only, no upload)

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build, sign, and upload to TestFlight

### ios push_appstore_metadata

```sh
[bundle exec] fastlane ios push_appstore_metadata
```

Push App Store text metadata (and screenshots, if present) via the API — never submits for review

### ios submit_appstore_for_review

```sh
[bundle exec] fastlane ios submit_appstore_for_review
```

Submit the current App Store Connect build for App Store review — irreversible, human-triggered only. Never called by CI automatically.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
