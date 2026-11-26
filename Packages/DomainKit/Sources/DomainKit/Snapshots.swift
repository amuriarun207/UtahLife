import Foundation

public struct DashboardData: Equatable, Sendable {
    public var location: Location
    public var greeting: String
    public var weather: Weather
    public var hourly: [HourlyForecast]
    public var airQuality: AirQuality
    public var traffic: TrafficSummary
    public var alerts: [LocalAlert]
    public var loadedAt: Date

    public init(
        location: Location,
        greeting: String,
        weather: Weather,
        hourly: [HourlyForecast],
        airQuality: AirQuality,
        traffic: TrafficSummary,
        alerts: [LocalAlert],
        loadedAt: Date
    ) {
        self.location = location
        self.greeting = greeting
        self.weather = weather
        self.hourly = hourly
        self.airQuality = airQuality
        self.traffic = traffic
        self.alerts = alerts
        self.loadedAt = loadedAt
    }
}

public struct EnvironmentSnapshot: Equatable, Sendable {
    public var weather: Weather
    public var hourly: [HourlyForecast]
    public var daily: [ForecastDay]
    public var airQuality: AirQuality

    public init(
        weather: Weather,
        hourly: [HourlyForecast],
        daily: [ForecastDay],
        airQuality: AirQuality
    ) {
        self.weather = weather
        self.hourly = hourly
        self.daily = daily
        self.airQuality = airQuality
    }
}

public struct TravelOverview: Equatable, Sendable {
    public var incidents: [TrafficIncident]
    public var roadConditions: [RoadCondition]
    public var summary: TrafficSummary
    public var commutes: [SavedCommute]
    public var cameras: [MockCamera]

    public init(
        incidents: [TrafficIncident],
        roadConditions: [RoadCondition],
        summary: TrafficSummary,
        commutes: [SavedCommute],
        cameras: [MockCamera]
    ) {
        self.incidents = incidents
        self.roadConditions = roadConditions
        self.summary = summary
        self.commutes = commutes
        self.cameras = cameras
    }
}
