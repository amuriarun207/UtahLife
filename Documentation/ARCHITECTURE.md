# Architecture

UtahLife is a SwiftUI app organized as local Swift packages. The data flow for every feature is unidirectional:

```text
SwiftUI view
  → Intent
  → Store (effects and use cases)
  → Action
  → pure Reducer
  → new immutable State
  → SwiftUI view
```

Reducers do not touch repositories, clocks, navigation side effects, or persistence. Stores perform that work and send the result back as an action. Views send intents and render state. They never call a repository.

## Packages

| Package | Responsibility |
| --- | --- |
| CoreKit | `AppError`, `AsyncValue`, greeting and timestamp formatting, delay policy, logging, sample copy, accessibility identifiers |
| DomainKit | Entities, repository protocols, use cases, AQI breakpoints, distance, filtering and sorting |
| DataKit | JSON fixtures, DTO decoding, mock repositories, in-memory alert read state, UserDefaults preferences, mock location provider |
| DesignSystem | Color, type, spacing, cards, chips, status pills, loading, empty, and error views, adaptive stacks |
| FeatureUI | Domain-aware cards, place and forecast rows, sample MapKit map, preview doubles |
| HomeFeature, ExploreFeature, TravelFeature, EnvironmentFeature, AlertsFeature | Feature state, intents, actions, reducers, stores, and screens |

DesignSystem depends only on CoreKit so visual primitives stay free of domain models. Shared cards that need `Weather` or `LocalAlert` live in FeatureUI. That extra package exists so Home and Travel can share a row without a feature-to-feature dependency, and without pulling SwiftUI into DomainKit.

## Composition

`AppDependencies.make()` is the composition root:

- Reads `-UtahLifeScenario` and optional `-UtahLifeResetPreferences`
- Builds one mock repository per data set and shares those instances across features
- Restores the selected sample location from `UserDefaults`, defaulting to Salt Lake City
- Creates a `MockLocationProvider` for a future opt-in location integration. The provider never requests Core Location permission
- Injects use cases into feature stores

`AppRouter` switches tabs when Home emits a navigation value. Changing location goes through `AppDependencies.select`, which persists the choice and forwards it to every store.

## Async state

`AsyncValue` is `idle`, `loading`, `loaded`, `empty`, or `failed`. A first load replaces content with `loading`. A refresh sets `isRefreshing` and keeps the current content until the effect returns. `AppError.empty` becomes the empty state. Other errors become `failed` and the screen offers **Try Again**.

Stores ignore a repeated `onAppear` after the first successful or failed load, and they drop stale responses with a generation counter.

## Fixtures

DataKit loads JSON with `Bundle.module`. Domain models are not `Codable`; DataKit decodes private DTOs and maps them. Timestamps are ISO 8601 with a numeric offset. The sample clock in the fixtures is 12 January 2026, 8:30 AM Mountain Time. The Home greeting uses the device clock in the selected location's time zone, injected through `DateProviding`, so tests can freeze it.

## Concurrency

Packages use Swift 6 language mode. Repositories are actors. Use cases are `Sendable` structs that hold protocol existentials. Stores and the composition root are `@MainActor`. Domain types do not import SwiftUI.

## Testing

- CoreKit, DomainKit, and DataKit tests run with `swift test` on macOS.
- Feature tests cover reducers and one store path per feature on the iOS simulator.
- `UtahLifeUITests` covers launch, tabs, navigation, location, search, travel filters, forecast selection, read state, and the empty and failure scenarios.

## Out of scope

No live UDOT, DEQ, AirNow, weather, or transit clients. No accounts, push permission, StoreKit, analytics, or routing.
