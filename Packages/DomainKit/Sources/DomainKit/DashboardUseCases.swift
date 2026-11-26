import CoreKit
import Foundation

public struct LoadHomeDashboardUseCase: Sendable {
    private let weatherRepository: any WeatherRepositoryProtocol
    private let airQualityRepository: any AirQualityRepositoryProtocol
    private let trafficRepository: any TrafficRepositoryProtocol
    private let alertsRepository: any AlertsRepositoryProtocol
    private let dates: any DateProviding

    public init(
        weatherRepository: any WeatherRepositoryProtocol,
        airQualityRepository: any AirQualityRepositoryProtocol,
        trafficRepository: any TrafficRepositoryProtocol,
        alertsRepository: any AlertsRepositoryProtocol,
        dates: any DateProviding
    ) {
        self.weatherRepository = weatherRepository
        self.airQualityRepository = airQualityRepository
        self.trafficRepository = trafficRepository
        self.alertsRepository = alertsRepository
        self.dates = dates
    }

    public func execute(location: Location) async throws -> DashboardData {
        try Task.checkCancellation()
        async let weatherTask = weatherRepository.currentWeather(for: location)
        async let hourlyTask = weatherRepository.hourlyForecast(for: location)
        async let airTask = airQualityRepository.airQuality(for: location)
        async let incidentsTask = trafficRepository.incidents(for: location)
        async let roadsTask = trafficRepository.roadConditions(for: location)
        async let alertsTask = alertsRepository.alerts(for: location)

        let weather = try await weatherTask
        let hourly = try await hourlyTask
        let airQuality = try await airTask
        let incidents = try await incidentsTask
        let roads = try await roadsTask
        let alerts = try await alertsTask

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = location.timeZone
        let greeting = DayPartGreeting.text(for: dates.now(), calendar: calendar)
        let summary = TrafficSummaryBuilder.make(incidents: incidents, roads: roads)
        let sortedHourly = hourly.sorted { $0.dateTime < $1.dateTime }
        let previewAlerts = FilterLocalAlertsUseCase.apply(
            alerts,
            query: FilterLocalAlertsUseCase.Query(categories: [], severities: [])
        )

        return DashboardData(
            location: location,
            greeting: greeting,
            weather: weather,
            hourly: sortedHourly,
            airQuality: airQuality.applyingDerivedCategory(),
            traffic: summary,
            alerts: previewAlerts,
            loadedAt: dates.now()
        )
    }
}

public struct LoadEnvironmentUseCase: Sendable {
    private let weatherRepository: any WeatherRepositoryProtocol
    private let airQualityRepository: any AirQualityRepositoryProtocol

    public init(
        weatherRepository: any WeatherRepositoryProtocol,
        airQualityRepository: any AirQualityRepositoryProtocol
    ) {
        self.weatherRepository = weatherRepository
        self.airQualityRepository = airQualityRepository
    }

    public func execute(location: Location) async throws -> EnvironmentSnapshot {
        try Task.checkCancellation()
        async let weatherTask = weatherRepository.currentWeather(for: location)
        async let hourlyTask = weatherRepository.hourlyForecast(for: location)
        async let dailyTask = weatherRepository.dailyForecast(for: location)
        async let airTask = airQualityRepository.airQuality(for: location)

        let daily = try await dailyTask
        return EnvironmentSnapshot(
            weather: try await weatherTask,
            hourly: try await hourlyTask.sorted { $0.dateTime < $1.dateTime },
            daily: daily.sorted { $0.date < $1.date },
            airQuality: try await airTask.applyingDerivedCategory()
        )
    }
}

public struct GetAirQualityUseCase: Sendable {
    private let repository: any AirQualityRepositoryProtocol

    public init(repository: any AirQualityRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(location: Location) async throws -> AirQuality {
        let reading = try await repository.airQuality(for: location)
        return reading.applyingDerivedCategory()
    }
}

public struct LoadTravelOverviewUseCase: Sendable {
    private let repository: any TrafficRepositoryProtocol

    public init(repository: any TrafficRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(location: Location) async throws -> TravelOverview {
        try Task.checkCancellation()
        async let incidentsTask = repository.incidents(for: location)
        async let roadsTask = repository.roadConditions(for: location)
        async let commutesTask = repository.savedCommutes(for: location)
        async let camerasTask = repository.cameras(for: location)
        let incidents = try await incidentsTask
        let roads = try await roadsTask
        return TravelOverview(
            incidents: FilterTrafficIncidentsUseCase.apply(
                incidents,
                query: FilterTrafficIncidentsUseCase.Query(severities: [], types: [])
            ),
            roadConditions: roads.sorted { $0.roadName < $1.roadName },
            summary: TrafficSummaryBuilder.make(incidents: incidents, roads: roads),
            commutes: try await commutesTask,
            cameras: try await camerasTask
        )
    }
}

public enum TrafficSummaryBuilder {
    public static func make(incidents: [TrafficIncident], roads: [RoadCondition]) -> TrafficSummary {
        let sorted = FilterTrafficIncidentsUseCase.apply(
            incidents,
            query: FilterTrafficIncidentsUseCase.Query(severities: [], types: [])
        )
        let headline: String
        if incidents.isEmpty {
            headline = "No sample incidents"
        } else {
            headline = "\(incidents.count) sample incidents"
        }
        let advisoryCount = roads.filter { $0.condition != .clear }.count
        let roadHeadline: String
        if roads.isEmpty {
            roadHeadline = "No sample road reports"
        } else if advisoryCount == 0 {
            roadHeadline = "Sample roads reported clear"
        } else {
            roadHeadline = "\(advisoryCount) sample road advisories"
        }
        return TrafficSummary(
            headline: headline,
            incidentCount: incidents.count,
            highestSeverity: sorted.map(\.severity).max(),
            topIncidents: Array(sorted.prefix(3)),
            roadConditionHeadline: roadHeadline
        )
    }
}
