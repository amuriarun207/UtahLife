# UtahLife

UtahLife is a mock-first iOS app for everyday local information in Salt Lake County. It runs entirely offline from local JSON fixtures. Nothing in this milestone is a live weather, air-quality, traffic, or place listing.

## Requirements

- Xcode 27.2 (this repository was built with Xcode 27.2 / Swift 6.4)
- iOS 26.0 or later
- No package accounts, API keys, or network access

The active developer directory on this machine may still point at Command Line Tools. Point command-line builds at Xcode:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

## Build and test

```sh
# App
xcodebuild -project UtahLife.xcodeproj -scheme UtahLife \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build

# Logic packages (macOS)
swift test --package-path Packages/CoreKit
swift test --package-path Packages/DomainKit
swift test --package-path Packages/DataKit

# Feature packages (iOS Simulator)
cd Packages/HomeFeature
xcodebuild -scheme HomeFeature \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' test

# App UI tests
xcodebuild -project UtahLife.xcodeproj -scheme UtahLife \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:UtahLifeUITests test
```

Repeat the app build or launch test with `iPhone 17e`, `iPhone 18 Pro Max`, and `iPhone Duo` when those simulators are installed. See `Documentation/DEVICE_ADAPTATION.md`.

## Launch scenarios

The app reads launch arguments. UI tests pass `-UtahLifeResetPreferences` so a previous sample location does not leak between runs.

| Arguments | Result |
| --- | --- |
| *(none)* | Populated Salt Lake County sample data. Default location is Salt Lake City, unless a location was saved on device. |
| `-UtahLifeScenario empty` | Locations remain available. Weather, places, travel, and alerts render their empty states. |
| `-UtahLifeScenario failure` | Sample loading fails and the app shows **Try Again**. |
| `-UtahLifeResetPreferences` | Clears the saved sample location and notification preferences before launch. |

## What this milestone includes

Five tabs, each using MVI (immutable state, intents, a pure reducer, effects that call use cases, and a store the view observes):

1. Home — daily sample dashboard
2. Explore — sample places, search, categories, and MapKit annotations
3. Travel — sample incidents, road conditions, commutes, and camera stills
4. Environment — sample weather, hourly and seven-day forecasts, and air quality
5. Alerts — sample alerts, read state, filters, and on-device notification preferences

The app does not request location or notification permission.

## Project layout

Local Swift packages live in `Packages/`. The app target is the composition root and is the only place that constructs mock repositories.

```text
UtahLife App
  ├── HomeFeature, ExploreFeature, TravelFeature, EnvironmentFeature, AlertsFeature
  ├── DataKit
  ├── DomainKit
  ├── DesignSystem
  └── CoreKit

Feature packages → FeatureUI, DomainKit, DesignSystem, CoreKit
FeatureUI → DomainKit, DesignSystem, CoreKit
DataKit → DomainKit, CoreKit
DomainKit → CoreKit
DesignSystem → CoreKit
```

`FeatureUI` holds shared cards and the sample map so feature packages do not depend on each other and DesignSystem does not import domain types.

## Data honesty

Every screen includes the label **Sample data. Not a live observation.** Travel times are not calculated. Camera cards are stills. Hospital and clinic rows are fictional listings and say they are not for emergencies.

## Next phase

Live data is intentionally not implemented. Extension points are the repository protocols in DomainKit and `LocationProviding`. See `IMPLEMENTATION_STATUS.md` for the live-data follow-up.
