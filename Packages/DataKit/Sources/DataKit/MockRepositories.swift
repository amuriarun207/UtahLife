import CoreKit
import DomainKit
import Foundation

public actor MockLocationRepository: LocationRepositoryProtocol {
    private let locationsCache: [Location]
    private let scenario: FixtureScenario
    private let delay: any DelayPolicy

    public init(
        scenario: FixtureScenario = .populated,
        delay: any DelayPolicy = ImmediateDelayPolicy(),
        bundle: Bundle? = nil
    ) throws {
        self.scenario = scenario
        self.delay = delay
        let source = bundle ?? .module
        let decoded: [LocationDTO] = try FixtureLoader.load("locations", from: source)
        locationsCache = decoded.map(\.model)
    }

    public func locations() async throws -> [Location] {
        await delay.wait()
        try Task.checkCancellation()
        if scenario == .failure {
            throw AppError.unavailable("Sample locations could not be loaded.")
        }
        return locationsCache
    }
}

public actor MockWeatherRepository: WeatherRepositoryProtocol {
    private let current: [Weather]
    private let hourly: [HourlyForecast]
    private let daily: [ForecastDay]
    private let scenario: FixtureScenario
    private let delay: any DelayPolicy

    public init(
        scenario: FixtureScenario = .populated,
        delay: any DelayPolicy = ImmediateDelayPolicy(),
        bundle: Bundle? = nil
    ) throws {
        self.scenario = scenario
        self.delay = delay
        let source = bundle ?? .module
        current = try FixtureLoader.models("weather_current", from: source) { (dto: WeatherDTO) in try dto.model() }
        hourly = try FixtureLoader.models("weather_hourly", from: source) { (dto: HourlyForecastDTO) in try dto.model() }
        daily = try FixtureLoader.models("weather_forecast", from: source) { (dto: ForecastDayDTO) in try dto.model() }
    }

    public func currentWeather(for location: Location) async throws -> Weather {
        try await gate(emptyMessage: "No sample weather is available for \(location.city).")
        guard let match = current.first(where: { $0.locationId == location.id }) else {
            throw AppError.empty("No sample weather for \(location.city).")
        }
        return match
    }

    public func hourlyForecast(for location: Location) async throws -> [HourlyForecast] {
        try await gateLists()
        return hourly.filter { $0.locationId == location.id }
    }

    public func dailyForecast(for location: Location) async throws -> [ForecastDay] {
        try await gateLists()
        return daily.filter { $0.locationId == location.id }
    }

    private func gate(emptyMessage: String) async throws {
        await delay.wait()
        try Task.checkCancellation()
        switch scenario {
        case .populated:
            return
        case .empty:
            throw AppError.empty(emptyMessage)
        case .failure:
            throw AppError.unavailable("Sample weather could not be loaded.")
        }
    }

    private func gateLists() async throws {
        await delay.wait()
        try Task.checkCancellation()
        if scenario == .failure {
            throw AppError.unavailable("Sample weather could not be loaded.")
        }
    }
}

public actor MockAirQualityRepository: AirQualityRepositoryProtocol {
    private let readings: [AirQuality]
    private let scenario: FixtureScenario
    private let delay: any DelayPolicy

    public init(
        scenario: FixtureScenario = .populated,
        delay: any DelayPolicy = ImmediateDelayPolicy(),
        bundle: Bundle? = nil
    ) throws {
        self.scenario = scenario
        self.delay = delay
        readings = try FixtureLoader.models("air_quality", from: bundle ?? .module) { (dto: AirQualityDTO) in try dto.model() }
    }

    public func airQuality(for location: Location) async throws -> AirQuality {
        await delay.wait()
        try Task.checkCancellation()
        switch scenario {
        case .failure:
            throw AppError.unavailable("Sample air quality could not be loaded.")
        case .empty:
            throw AppError.empty("No sample air quality is available for \(location.city).")
        case .populated:
            guard let match = readings.first(where: { $0.locationId == location.id }) else {
                throw AppError.empty("No sample air quality for \(location.city).")
            }
            return match
        }
    }
}

public actor MockTrafficRepository: TrafficRepositoryProtocol {
    private let incidentsCache: [TrafficIncident]
    private let roadsCache: [RoadCondition]
    private let commutesCache: [SavedCommute]
    private let camerasCache: [MockCamera]
    private let scenario: FixtureScenario
    private let delay: any DelayPolicy

    public init(
        scenario: FixtureScenario = .populated,
        delay: any DelayPolicy = ImmediateDelayPolicy(),
        bundle: Bundle? = nil
    ) throws {
        self.scenario = scenario
        self.delay = delay
        let source = bundle ?? .module
        incidentsCache = try FixtureLoader.models("traffic_incidents", from: source) { (dto: TrafficIncidentDTO) in try dto.model() }
        roadsCache = try FixtureLoader.models("road_conditions", from: source) { (dto: RoadConditionDTO) in try dto.model() }
        commutesCache = try FixtureLoader.models("saved_commutes", from: source) { (dto: SavedCommuteDTO) in dto.model }
        camerasCache = try FixtureLoader.models("mock_cameras", from: source) { (dto: MockCameraDTO) in dto.model }
    }

    public func incidents(for location: Location) async throws -> [TrafficIncident] {
        try await lists(failure: "Sample traffic could not be loaded.")
        return incidentsCache.filter { $0.locationId == location.id }
    }

    public func roadConditions(for location: Location) async throws -> [RoadCondition] {
        try await lists(failure: "Sample road conditions could not be loaded.")
        return roadsCache.filter { $0.locationId == location.id }
    }

    public func savedCommutes(for location: Location) async throws -> [SavedCommute] {
        try await lists(failure: "Sample commutes could not be loaded.")
        return commutesCache.filter { $0.locationId == location.id }
    }

    public func cameras(for location: Location) async throws -> [MockCamera] {
        try await lists(failure: "Sample cameras could not be loaded.")
        return camerasCache.filter { $0.locationId == location.id }
    }

    private func lists(failure: String) async throws {
        await delay.wait()
        try Task.checkCancellation()
        if scenario == .failure {
            throw AppError.unavailable(failure)
        }
    }
}

public actor MockLocalPlacesRepository: LocalPlacesRepositoryProtocol {
    private let placesCache: [LocalPlace]
    private let scenario: FixtureScenario
    private let delay: any DelayPolicy

    public init(
        scenario: FixtureScenario = .populated,
        delay: any DelayPolicy = ImmediateDelayPolicy(),
        bundle: Bundle? = nil
    ) throws {
        self.scenario = scenario
        self.delay = delay
        placesCache = try FixtureLoader.models("local_places", from: bundle ?? .module) { (dto: LocalPlaceDTO) in try dto.model() }
    }

    public func places(near location: Location) async throws -> [LocalPlace] {
        await delay.wait()
        try Task.checkCancellation()
        if scenario == .failure {
            throw AppError.unavailable("Sample places could not be loaded.")
        }
        guard scenario == .populated else { return [] }
        return placesCache.filter { $0.locationId == location.id }
    }
}

public actor MockAlertsRepository: AlertsRepositoryProtocol {
    private var alertsCache: [LocalAlert]
    private var readIDs: Set<String>
    private let scenario: FixtureScenario
    private let delay: any DelayPolicy

    public init(
        scenario: FixtureScenario = .populated,
        delay: any DelayPolicy = ImmediateDelayPolicy(),
        bundle: Bundle? = nil
    ) throws {
        self.scenario = scenario
        self.delay = delay
        alertsCache = try FixtureLoader.models("local_alerts", from: bundle ?? .module) { (dto: LocalAlertDTO) in try dto.model() }
        readIDs = Set(alertsCache.filter(\.isRead).map(\.id))
    }

    public func alerts(for location: Location) async throws -> [LocalAlert] {
        await delay.wait()
        try Task.checkCancellation()
        if scenario == .failure {
            throw AppError.unavailable("Sample alerts could not be loaded.")
        }
        guard scenario == .populated else { return [] }
        return alertsCache
            .filter { $0.locationId == location.id }
            .map { alert in
                var copy = alert
                copy.isRead = readIDs.contains(alert.id)
                return copy
            }
    }

    public func markAsRead(id: String) async throws {
        try await ensureWritable()
        guard alertsCache.contains(where: { $0.id == id }) else {
            throw AppError.unavailable("Sample alert \(id) was not found.")
        }
        readIDs.insert(id)
    }

    public func markAllAsRead() async throws {
        try await ensureWritable()
        readIDs.formUnion(alertsCache.map(\.id))
    }

    private func ensureWritable() async throws {
        await delay.wait()
        try Task.checkCancellation()
        if scenario == .failure {
            throw AppError.unavailable("Sample alerts could not be updated.")
        }
    }
}

public actor UserDefaultsLocationPreferences: LocationPreferencesProtocol {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults, key: String = "utahlife.selectedLocationID") {
        self.defaults = defaults
        self.key = key
    }

    public func selectedLocationID() async -> String? {
        defaults.string(forKey: key)
    }

    public func setSelectedLocationID(_ id: String) async {
        defaults.set(id, forKey: key)
    }
}

public actor UserDefaultsNotificationPreferences: NotificationPreferencesRepositoryProtocol {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults, key: String = "utahlife.notificationPreferences") {
        self.defaults = defaults
        self.key = key
    }

    public func load() async -> NotificationPreferences {
        guard let data = defaults.data(forKey: key) else {
            return .sampleDefault
        }
        return (try? JSONDecoder().decode(NotificationPreferences.self, from: data)) ?? .sampleDefault
    }

    public func save(_ preferences: NotificationPreferences) async {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        defaults.set(data, forKey: key)
    }
}

public actor MockLocationProvider: LocationProviding {
    private let locationsRepository: any LocationRepositoryProtocol
    private let preferences: any LocationPreferencesProtocol

    public init(
        locationsRepository: any LocationRepositoryProtocol,
        preferences: any LocationPreferencesProtocol
    ) {
        self.locationsRepository = locationsRepository
        self.preferences = preferences
    }

    public func currentLocation() async throws -> Location {
        let available = try await locationsRepository.locations()
        if let saved = await preferences.selectedLocationID(),
           let match = available.first(where: { $0.id == saved }) {
            return match
        }
        guard let fallback = available.first(where: \.isDefault) ?? available.first else {
            throw AppError.empty("No sample locations are available.")
        }
        return fallback
    }
}
