import CoreKit
import DataKit
import DomainKit
import Foundation
import XCTest

final class DataKitTests: XCTestCase {
    func testFixturesDecodeForEveryLocation() async throws {
        let locations = try MockLocationRepository()
        let weather = try MockWeatherRepository()
        let air = try MockAirQualityRepository()
        let traffic = try MockTrafficRepository()
        let places = try MockLocalPlacesRepository()
        let alerts = try MockAlertsRepository()
        let catalog = try await locations.locations()
        XCTAssertEqual(catalog.count, 7)
        XCTAssertEqual(catalog.first(where: \.isDefault)?.id, "slc")

        for location in catalog {
            let current = try await weather.currentWeather(for: location)
            XCTAssertTrue(current.isMockData)
            XCTAssertEqual(current.temperature.unitSymbol, "°F")
            let hourly = try await weather.hourlyForecast(for: location)
            XCTAssertEqual(hourly.count, 8)
            let daily = try await weather.dailyForecast(for: location)
            XCTAssertEqual(daily.count, 7)
            let reading = try await air.airQuality(for: location)
            XCTAssertEqual(reading.sourceLabel, "Local sample fixture")
            let incidents = try await traffic.incidents(for: location)
            XCTAssertFalse(incidents.isEmpty)
            let roads = try await traffic.roadConditions(for: location)
            XCTAssertFalse(roads.isEmpty)
            let nearby = try await places.places(near: location)
            XCTAssertGreaterThanOrEqual(nearby.count, 8)
            let locationAlerts = try await alerts.alerts(for: location)
            XCTAssertFalse(locationAlerts.isEmpty)
        }
    }

    func testSaltLakeIncidentsIncludeEverySeverity() async throws {
        let repository = try MockTrafficRepository()
        let incidents = try await repository.incidents(for: PreviewCatalog.saltLakeCity)
        XCTAssertEqual(Set(incidents.map(\.severity)), Set(IncidentSeverity.allCases))
        XCTAssertTrue(incidents.allSatisfy(\.isMockData))
        let commutes = try await repository.savedCommutes(for: PreviewCatalog.saltLakeCity)
        XCTAssertEqual(commutes.count, 2)
    }

    func testMarkReadIsIdempotentAndLocal() async throws {
        let repository = try MockAlertsRepository()
        let before = try await repository.alerts(for: PreviewCatalog.saltLakeCity)
        let unread = try XCTUnwrap(before.first(where: { $0.isRead == false }))
        try await repository.markAsRead(id: unread.id)
        try await repository.markAsRead(id: unread.id)
        let after = try await repository.alerts(for: PreviewCatalog.saltLakeCity)
        XCTAssertEqual(after.first(where: { $0.id == unread.id })?.isRead, true)
        XCTAssertEqual(before.count, after.count)
        try await repository.markAllAsRead()
        let allRead = try await repository.alerts(for: PreviewCatalog.saltLakeCity)
        XCTAssertTrue(allRead.allSatisfy(\.isRead))
    }

    func testEmptyAndFailureScenarios() async throws {
        let emptyWeather = try MockWeatherRepository(scenario: .empty)
        do {
            _ = try await emptyWeather.currentWeather(for: PreviewCatalog.saltLakeCity)
            XCTFail("Expected empty weather")
        } catch let error as AppError {
            XCTAssertTrue(error.isEmpty)
        }
        let emptyPlaces = try MockLocalPlacesRepository(scenario: .empty)
        let places = try await emptyPlaces.places(near: PreviewCatalog.saltLakeCity)
        XCTAssertTrue(places.isEmpty)

        let failed = try MockAlertsRepository(scenario: .failure)
        do {
            _ = try await failed.alerts(for: PreviewCatalog.saltLakeCity)
            XCTFail("Expected failure")
        } catch let error as AppError {
            XCTAssertEqual(error, .unavailable("Sample alerts could not be loaded."))
        }
    }

    func testLocationProviderUsesSavedSampleWithoutDeviceLocation() async throws {
        let defaults = UserDefaults(suiteName: "DataKitTests.locations") ?? .standard
        defaults.removePersistentDomain(forName: "DataKitTests.locations")
        let preferences = UserDefaultsLocationPreferences(defaults: defaults)
        let provider = MockLocationProvider(
            locationsRepository: try MockLocationRepository(),
            preferences: preferences
        )
        let initial = try await provider.currentLocation()
        XCTAssertEqual(initial.id, "slc")
        await preferences.setSelectedLocationID("draper")
        let selected = try await provider.currentLocation()
        XCTAssertEqual(selected.city, "Draper")
    }

    func testNotificationPreferencesRoundTrip() async throws {
        let defaults = UserDefaults(suiteName: "DataKitTests.notifications") ?? .standard
        defaults.removePersistentDomain(forName: "DataKitTests.notifications")
        let repository = UserDefaultsNotificationPreferences(defaults: defaults)
        var preferences = await repository.load()
        XCTAssertFalse(preferences.masterEnabled)
        preferences.masterEnabled = true
        preferences.categories[.snow] = false
        await repository.save(preferences)
        let loaded = await repository.load()
        XCTAssertTrue(loaded.masterEnabled)
        XCTAssertEqual(loaded.categories[.snow], false)
        XCTAssertFalse(loaded.isEnabled(.snow))
        XCTAssertTrue(loaded.isEnabled(.weather))
    }

    func testScenarioParser() {
        XCTAssertEqual(FixtureScenario.from(arguments: []), .populated)
        XCTAssertEqual(
            FixtureScenario.from(arguments: ["-UtahLifeScenario", "failure"]),
            .failure
        )
        XCTAssertEqual(
            FixtureScenario.from(arguments: ["-UtahLifeScenario", "unknown"]),
            .populated
        )
    }
}
