import Foundation

public protocol WeatherRepositoryProtocol: Sendable {
    func currentWeather(for location: Location) async throws -> Weather
    func hourlyForecast(for location: Location) async throws -> [HourlyForecast]
    func dailyForecast(for location: Location) async throws -> [ForecastDay]
}

public protocol AirQualityRepositoryProtocol: Sendable {
    func airQuality(for location: Location) async throws -> AirQuality
}

public protocol TrafficRepositoryProtocol: Sendable {
    func incidents(for location: Location) async throws -> [TrafficIncident]
    func roadConditions(for location: Location) async throws -> [RoadCondition]
    func savedCommutes(for location: Location) async throws -> [SavedCommute]
    func cameras(for location: Location) async throws -> [MockCamera]
}

public protocol LocalPlacesRepositoryProtocol: Sendable {
    func places(near location: Location) async throws -> [LocalPlace]
}

public protocol AlertsRepositoryProtocol: Sendable {
    func alerts(for location: Location) async throws -> [LocalAlert]
    func markAsRead(id: String) async throws
    func markAllAsRead() async throws
}

public protocol LocationRepositoryProtocol: Sendable {
    func locations() async throws -> [Location]
}

public protocol LocationPreferencesProtocol: Sendable {
    func selectedLocationID() async -> String?
    func setSelectedLocationID(_ id: String) async
}

public protocol NotificationPreferencesRepositoryProtocol: Sendable {
    func load() async -> NotificationPreferences
    func save(_ preferences: NotificationPreferences) async
}

/// Future device-location integration point. The mock provider never requests permission.
public protocol LocationProviding: Sendable {
    func currentLocation() async throws -> Location
}
