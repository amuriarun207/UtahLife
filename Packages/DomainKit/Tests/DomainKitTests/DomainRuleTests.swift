import CoreKit
import DomainKit
import Foundation
import XCTest

final class DomainRuleTests: XCTestCase {
    func testAQIBreakpoints() {
        XCTAssertEqual(AQICategory.category(for: 0), .good)
        XCTAssertEqual(AQICategory.category(for: 50), .good)
        XCTAssertEqual(AQICategory.category(for: 51), .moderate)
        XCTAssertEqual(AQICategory.category(for: 100), .moderate)
        XCTAssertEqual(AQICategory.category(for: 101), .unhealthyForSensitiveGroups)
        XCTAssertEqual(AQICategory.category(for: 150), .unhealthyForSensitiveGroups)
        XCTAssertEqual(AQICategory.category(for: 151), .unhealthy)
        XCTAssertEqual(AQICategory.category(for: 200), .unhealthy)
        XCTAssertEqual(AQICategory.category(for: 201), .veryUnhealthy)
        XCTAssertEqual(AQICategory.category(for: 300), .veryUnhealthy)
        XCTAssertEqual(AQICategory.category(for: 301), .hazardous)
    }

    func testAirQualityUseCaseReplacesFixtureCategory() async throws {
        let repository = StaticAirQualityRepository(
            reading: AirQuality(
                locationId: PreviewCatalog.saltLakeCity.id,
                observedAt: PreviewCatalog.observedAt,
                aqi: 175,
                category: .good,
                primaryPollutant: "PM2.5",
                sourceLabel: "fixture",
                isMockData: true
            )
        )
        let useCase = GetAirQualityUseCase(repository: repository)
        let result = try await useCase.execute(location: PreviewCatalog.saltLakeCity)
        XCTAssertEqual(result.category, .unhealthy)
        XCTAssertTrue(result.isMockData)
    }

    func testTrafficFilterAndSortAreDeterministic() {
        let incidents = [PreviewCatalog.lowIncident, PreviewCatalog.moderateIncident, PreviewCatalog.incident]
        let filtered = FilterTrafficIncidentsUseCase.apply(
            incidents,
            query: FilterTrafficIncidentsUseCase.Query(severities: [.critical, .low], types: [])
        )
        XCTAssertEqual(filtered.map(\.id), ["slc-closure", "slc-slowdown"])

        let typed = FilterTrafficIncidentsUseCase.apply(
            incidents,
            query: FilterTrafficIncidentsUseCase.Query(severities: [], types: [.roadwork])
        )
        XCTAssertEqual(typed.map(\.id), ["slc-roadwork"])

        let sameSeverity = [
            traffic(id: "b", updated: 20),
            traffic(id: "a", updated: 20),
            traffic(id: "c", updated: 10)
        ]
        let sorted = FilterTrafficIncidentsUseCase.apply(
            sameSeverity,
            query: FilterTrafficIncidentsUseCase.Query(severities: [], types: [])
        )
        XCTAssertEqual(sorted.map(\.id), ["a", "b", "c"])
    }

    func testAlertFiltersComposeAndUnreadSortsFirst() {
        let olderUnread = alert(id: "older-unread", read: false, createdOffset: -100, category: .traffic, severity: .info)
        let newerRead = alert(id: "newer-read", read: true, createdOffset: 100, category: .traffic, severity: .warning)
        let other = alert(id: "other", read: false, createdOffset: 50, category: .weather, severity: .warning)
        let results = FilterLocalAlertsUseCase.apply(
            [newerRead, olderUnread, other],
            query: FilterLocalAlertsUseCase.Query(categories: [.traffic], severities: [])
        )
        XCTAssertEqual(results.map(\.id), ["older-unread", "newer-read"])

        let both = FilterLocalAlertsUseCase.apply(
            [newerRead, olderUnread, other],
            query: FilterLocalAlertsUseCase.Query(categories: [.traffic], severities: [.warning])
        )
        XCTAssertEqual(both.map(\.id), ["newer-read"])
    }

    func testSearchMatchesNameOrCategoryAndSortsByDistance() {
        let farPark = LocalPlace(
            id: "far-park",
            locationId: "slc",
            name: "Far Park",
            category: .parks,
            address: "Draper",
            latitude: 40.52,
            longitude: -111.86,
            description: "Far",
            isMockData: true
        )
        let places = [farPark, PreviewCatalog.library, PreviewCatalog.park]
        let libraries = SearchLocalPlacesUseCase.filter(
            places,
            near: PreviewCatalog.saltLakeCity,
            query: SearchLocalPlacesUseCase.Query(text: "library", category: nil)
        )
        XCTAssertEqual(libraries.map(\.id), [PreviewCatalog.library.id])

        let parks = SearchLocalPlacesUseCase.filter(
            places,
            near: PreviewCatalog.saltLakeCity,
            query: SearchLocalPlacesUseCase.Query(text: "", category: .parks)
        )
        XCTAssertEqual(parks.map(\.id), [PreviewCatalog.park.id, farPark.id])
    }

    func testDistanceLabel() {
        let miles = DistanceCalculator.miles(
            fromLatitude: PreviewCatalog.saltLakeCity.latitude,
            fromLongitude: PreviewCatalog.saltLakeCity.longitude,
            toLatitude: PreviewCatalog.westJordan.latitude,
            toLongitude: PreviewCatalog.westJordan.longitude
        )
        XCTAssertGreaterThan(miles, 8)
        XCTAssertLessThan(miles, 15)
        XCTAssertEqual(DistanceCalculator.label(miles: 0.04), "Under 0.1 mi")
        XCTAssertEqual(DistanceCalculator.label(miles: 1.26), "1.3 mi")
    }

    func testSelectLocationRejectsUnknownAndRestoresSaved() async throws {
        let preferences = MemoryLocationPreferences()
        let useCase = SelectLocationUseCase(preferences: preferences)
        let available = [PreviewCatalog.saltLakeCity, PreviewCatalog.westJordan]
        let selected = try await useCase.execute(location: PreviewCatalog.westJordan, available: available)
        XCTAssertEqual(selected.id, "west-jordan")
        let restored = try await useCase.restore(available: available)
        XCTAssertEqual(restored.id, "west-jordan")

        let unknown = PreviewCatalog.saltLakeCity
        var missing = unknown
        missing.id = "missing"
        do {
            _ = try await useCase.execute(location: missing, available: available)
            XCTFail("Expected unknown location to fail")
        } catch let error as AppError {
            XCTAssertEqual(error, .unavailable("That location is not in the sample list."))
        }
    }

    func testDashboardOrchestratesRepositories() async throws {
        let useCase = LoadHomeDashboardUseCase(
            weatherRepository: StaticWeatherRepository(),
            airQualityRepository: StaticAirQualityRepository(reading: PreviewCatalog.airQuality),
            trafficRepository: StaticTrafficRepository(),
            alertsRepository: StaticAlertsRepository(),
            dates: FixedDateProvider(date: date("2026-01-12T15:30:00Z"))
        )
        let dashboard = try await useCase.execute(location: PreviewCatalog.saltLakeCity)
        XCTAssertEqual(dashboard.greeting, "Good morning")
        XCTAssertEqual(dashboard.weather.temperature.display, "31°F")
        XCTAssertEqual(dashboard.traffic.highestSeverity, .critical)
        XCTAssertEqual(dashboard.alerts.first?.id, PreviewCatalog.unreadAlert.id)
        XCTAssertTrue(dashboard.airQuality.isMockData)
    }

    func testSummaryDescribesEmptyRoads() {
        let summary = TrafficSummaryBuilder.make(incidents: [], roads: [])
        XCTAssertEqual(summary.headline, "No sample incidents")
        XCTAssertEqual(summary.roadConditionHeadline, "No sample road reports")
        XCTAssertNil(summary.highestSeverity)
    }

    private func date(_ string: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string) ?? Date(timeIntervalSince1970: 0)
    }

    private func traffic(id: String, updated: TimeInterval) -> TrafficIncident {
        TrafficIncident(
            id: id,
            locationId: "slc",
            title: id,
            description: "sample",
            road: "I-15",
            area: "Sample",
            severity: .low,
            incidentType: .congestion,
            status: .active,
            latitude: 0,
            longitude: 0,
            reportedAt: Date(timeIntervalSince1970: updated),
            updatedAt: Date(timeIntervalSince1970: updated),
            isMockData: true
        )
    }

    private func alert(
        id: String,
        read: Bool,
        createdOffset: TimeInterval,
        category: AlertCategory,
        severity: AlertSeverity
    ) -> LocalAlert {
        LocalAlert(
            id: id,
            locationId: "slc",
            title: id,
            summary: "sample",
            details: "sample",
            category: category,
            severity: severity,
            area: "Sample",
            createdAt: Date(timeIntervalSince1970: createdOffset),
            expiresAt: nil,
            isRead: read,
            isMockData: true
        )
    }
}

private actor MemoryLocationPreferences: LocationPreferencesProtocol {
    private var stored: String?

    func selectedLocationID() async -> String? { stored }

    func setSelectedLocationID(_ id: String) async {
        stored = id
    }
}

private struct StaticWeatherRepository: WeatherRepositoryProtocol {
    func currentWeather(for location: Location) async throws -> Weather { PreviewCatalog.weather }
    func hourlyForecast(for location: Location) async throws -> [HourlyForecast] { PreviewCatalog.hourly }
    func dailyForecast(for location: Location) async throws -> [ForecastDay] { PreviewCatalog.daily }
}

private struct StaticAirQualityRepository: AirQualityRepositoryProtocol {
    var reading: AirQuality
    func airQuality(for location: Location) async throws -> AirQuality { reading }
}

private struct StaticTrafficRepository: TrafficRepositoryProtocol {
    func incidents(for location: Location) async throws -> [TrafficIncident] {
        [PreviewCatalog.lowIncident, PreviewCatalog.incident, PreviewCatalog.moderateIncident]
    }
    func roadConditions(for location: Location) async throws -> [RoadCondition] { [PreviewCatalog.road] }
    func savedCommutes(for location: Location) async throws -> [SavedCommute] { [PreviewCatalog.commute] }
    func cameras(for location: Location) async throws -> [MockCamera] { [PreviewCatalog.camera] }
}

private actor StaticAlertsRepository: AlertsRepositoryProtocol {
    func alerts(for location: Location) async throws -> [LocalAlert] {
        [PreviewCatalog.readAlert, PreviewCatalog.unreadAlert]
    }
    func markAsRead(id: String) async throws {}
    func markAllAsRead() async throws {}
}
