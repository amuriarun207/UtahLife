# Use cases

Use cases live in DomainKit. They are the only types stores use to read or write sample data. Views do not call them.

## LoadHomeDashboardUseCase

Loads current weather, an hourly preview, air quality, incidents, road conditions, and alerts together. It derives the AQI category from the numeric index, builds a traffic summary, sorts alerts with unread items first, and formats the greeting from an injected clock in the location time zone.

## LoadEnvironmentUseCase

Loads current conditions, hourly forecast, and a seven-day forecast, sorted by time, plus air quality with the derived category.

## GetAirQualityUseCase

Replaces whatever category string was stored in a fixture with `AQICategory.category(for:)`. Breakpoints are 0–50 good, 51–100 moderate, 101–150 unhealthy for sensitive groups, 151–200 unhealthy, 201–300 very unhealthy, and 301+ hazardous. Guidance strings say they are informational sample wording, not medical advice.

## LoadTravelOverviewUseCase

Loads incidents, road conditions, sample commutes, and sample cameras. Incidents are sorted by severity (critical first), then by `updatedAt`, then by id. The summary counts incidents and road advisories. It does not invent a travel time.

## SearchLocalPlacesUseCase

Filters an already loaded catalog by optional category and by a case-insensitive match on name, category title, or address. Results are sorted by haversine distance from the selected sample coordinate, then by name.

## FilterTrafficIncidentsUseCase

An empty severity set means all severities. An empty type set means all types. The two filters combine with AND. Sort order matches the travel overview.

## FilterLocalAlertsUseCase

Category and severity filters combine with AND. Unread alerts sort ahead of read alerts. Within that, newer `createdAt` comes first, then id.

## LoadAlertsUseCase

Reads alerts for a location and applies the default unread-first sort before the feature reducer applies the active filters again.

## MarkAlertAsReadUseCase and MarkAllAlertsAsReadUseCase

Update the in-memory read set on the shared alerts repository and return the location's alerts. Marking an id twice is idempotent. Read state is not sent anywhere.

## SelectLocationUseCase

Accepts only ids present in the fixture catalog, persists the id locally, and restores the saved id or the location marked `isDefault` (Salt Lake City).

## NotificationPreferencesUseCase

Loads and saves `NotificationPreferences` on device. The master switch defaults to off. Saving a preference does not call `UNUserNotificationCenter` and does not request permission.

## LocationProviding

`MockLocationProvider.currentLocation()` returns the saved sample location or Salt Lake City. It is constructed at launch so a future opt-in Core Location implementation can replace it without changing feature stores.
