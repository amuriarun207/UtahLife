# Implementation status

Mock-first UtahLife is implemented as a local SwiftUI app. Every screen reads Salt Lake County JSON fixtures. There is no network client, account, or live weather, air, traffic, or place feed.

## Phase 0 — inspection

The repository started with `CURSOR_BUILD_INSTRUCTIONS.md`, `LICENSE`, and `.gitignore`. There was no Xcode project and no app source.

| Item | Result |
| --- | --- |
| Xcode | 27.2 (build 27B52), `/Applications/Xcode.app` |
| Swift | 6.4.2 (swiftlang-6.4.2.1.9) |
| Command-line developer dir | Builds in this session set `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`. The machine's `xcode-select` was not changed. |
| Deployment target | iOS 26.0. There was no previous target to preserve. |
| Language mode | Swift 6, strict concurrency complete |
| Bundle id | `com.utahlife.app` |
| iPhone Duo | Available. iOS 27.1 device `731FEC83-CB6D-4F06-A4E3-1A3C12E1CDDE`. iOS 27.2 device `B4748265-E465-4507-9A04-DACEBD5BF343`. |
| Other simulators used | iPhone 17 / iOS 26.5 (`CF2B2CF1-10EB-4449-83F4-A2385ACA4B5C`), iPhone 17e / iOS 27.2 (`DCCE43E8-F7AD-42B2-8D2E-22933BBBFDF2`), iPhone 18 Pro Max / iOS 27.2 (`99A57654-D018-45EC-870E-04FE767E0F6E`) |

## Package graph

```text
UtahLife app
  → HomeFeature, ExploreFeature, TravelFeature, EnvironmentFeature, AlertsFeature
  → DataKit → DomainKit → CoreKit
  → DesignSystem → CoreKit
  → FeatureUI → DomainKit, DesignSystem, CoreKit
```

Feature packages depend on FeatureUI, DomainKit, DesignSystem, and CoreKit. They do not depend on each other or on DataKit. The app is the composition root (`AppDependencies.make()`).

FeatureUI exists so shared cards and the sample map can use domain types without a feature-to-feature dependency and without pulling those types into DesignSystem. DomainKit does not import SwiftUI.

## What the app does

Five tabs, each with immutable state, intents, a pure reducer, and a store that calls use cases:

- Home dashboard for the selected sample city
- Explore search, categories, list, and MapKit annotations
- Travel incidents, filters, road conditions, sample commutes, and camera stills
- Environment hourly and seven-day forecast plus air quality
- Alerts filters, in-memory read state, and on-device notification preferences

Default location is Salt Lake City. The choice is stored in UserDefaults. `MockLocationProvider` is constructed at launch and does not request Core Location permission. Notification preferences do not call `UNUserNotificationCenter`.

Launch arguments:

- `-UtahLifeScenario empty` keeps locations and shows empty feature states
- `-UtahLifeScenario failure` fails sample loading and shows Try Again
- `-UtahLifeResetPreferences` clears the saved location and notification preferences

Copy on screen says the data is a sample and not a live observation.

## Verification

Commands used `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.

### Logic packages (`swift test`, this session)

| Package | Result |
| --- | --- |
| CoreKit | 5 tests passed |
| DomainKit | 9 tests passed |
| DataKit | 7 tests passed |

`swift test` also reported a Swift Testing run of 0 tests. The XCTest suites above are the tests that ran.

### Feature packages

Earlier in this implementation, each feature package was tested with `xcodebuild -scheme <Package> -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' test` and reported TEST SUCCEEDED:

| Package | Tests |
| --- | --- |
| HomeFeature | 6 |
| EnvironmentFeature | 5 |
| TravelFeature | 5 |
| ExploreFeature | 3 |
| AlertsFeature | 5 |

Those runs were not repeated after `AdaptiveColumnGrid` stopped using `LazyVGrid`. The feature tests cover reducers and stores, not that layout.

### App UI tests

All seven `UtahLifeUITests` methods passed on:

- iPhone 17, iOS 26.5 (re-run after the tab-rail helper and the column-layout change). About 100 seconds of test time.
- iPhone Duo, iOS 27.2, device `B4748265-E465-4507-9A04-DACEBD5BF343`, build 24B91016s. About 126 seconds of test time. `xcodebuild` exit 0.

`testLaunchAndAllTabs` also passed on:

- iPhone 17e, iOS 27.2 (39.1 seconds)
- iPhone 18 Pro Max, iOS 27.2 (40.7 seconds)

The full seven-test suite was not repeated on 17e or 18 Pro Max. The launch test on those two devices ran before the tab helper. Both devices use a normal tab bar, which is the path the helper still takes when `tabBars` exists. The full suite after the helper passed on iPhone 17.

## iPhone Duo

`simctl io enumerate` on the iOS 27.2 Duo listed two integrated displays, both powered on:

| Display | Name | Pixels | Scale | Point size |
| --- | --- | --- | --- | --- |
| Outer | `primary` / LCD | 1398 × 2034 | 3x | 466 × 678 |
| Inner | `primary-1` / LCD-1 | 2007 × 2853 | 3x | 669 × 951 |

`Documentation/Screenshots/duo-primary.png` is the outer display after launching `com.utahlife.app`. Home shows the sample banner, Salt Lake City, weather, the hourly row, air quality, and a trailing rail with the five tabs. The UI test hierarchy reported one window, 466 × 678 points. Content is inset so the rail does not cover the weather card. The hourly row is a horizontal scroller, so the last hour at the edge is clipped by the scroller.

`Documentation/Screenshots/duo-primary-1.png` is the inner display at the same moment. The framebuffer is black. The app had no window on that display.

`simctl ui` can set appearance, contrast, and content size. It has no fold, unfold, or posture command. Device Hub was not driven. These were not tested:

- inner display with the app visible
- fold, unfold, and intermediate poses
- landscape
- the 760-point side-by-side map and list layout

`bootstatus` printed `Data Migration Failed` and then returned. Install and launch still succeeded, and the UI suite passed on that simulator.

On the outer display the system presents tabs as a trailing rail, not as an accessibility `TabBar`. UI tests tap that rail when no tab bar exists. Standard iPhones in this session still expose a tab bar.

## Definition of done

- [x] UtahLife launches on the simulators listed above.
- [x] All five tabs work, including the Duo outer rail.
- [x] All five features use MVI.
- [x] Feature state is immutable. Reducers are pure functions.
- [x] Stores call use cases. Views do not call repositories.
- [x] Data comes from local fixtures.
- [x] The app does not use the network.
- [x] Local packages resolve with no remote dependencies.
- [x] Package dependencies are one-directional.
- [x] DesignSystem components are shared by the features.
- [x] Location selection works from the sample catalog.
- [x] Loading, empty, error, and populated states exist and are covered by tests.
- [ ] Light and dark appearance were not switched in the simulator. Previews include a dark Home variant. Dynamic Type uses text styles; a larger content size was not run in the simulator.
- [x] Compact layout was exercised on iPhone 17, iPhone 17e, and the Duo outer display. A larger phone was launched on iPhone 18 Pro Max.
- [ ] Expanded width (map beside list at 760 points) and iPhone Duo inner, fold, and unfold poses were not run. See `Documentation/DEVICE_ADAPTATION.md`.
- [x] On-screen copy does not claim live observations.
- [x] README and `Documentation/` describe the architecture, use cases, and how to build.
- [x] This file records the commands that actually ran.

## Remaining notes

- An xcodebuild subprocess sometimes logs `xcrun: error: unable to find utility "simctl"` while collecting diagnostics, because that subprocess does not see `DEVELOPER_DIR`. The test result itself still completed.
- Xcode logs `IDESchemeActionDeviceRecord` `invalidDigitCount` for the iOS 27.2 build number `24B91016s`. That is Xcode bookkeeping, not an app failure.
- `AppIntents` metadata extraction warns that the app does not link AppIntents. The app does not use App Intents.

## Live data — not started

Do not add UDOT, Utah DEQ, AirNow, National Weather Service, or UTA clients in this milestone. The extension points are the repository protocols and `LocationProviding` in DomainKit. A future client should sit behind those protocols in DataKit and be constructed only from `AppDependencies`. Location permission, if it is ever added, has to be opt-in and must not be requested at launch.
