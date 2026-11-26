import Foundation

public enum WeatherCondition: String, Equatable, Sendable, CaseIterable {
    case clear
    case partlyCloudy
    case cloudy
    case rain
    case snow
    case wind
    case fog
    case thunderstorm

    public var title: String {
        switch self {
        case .clear: return "Clear"
        case .partlyCloudy: return "Partly cloudy"
        case .cloudy: return "Cloudy"
        case .rain: return "Rain"
        case .snow: return "Snow"
        case .wind: return "Windy"
        case .fog: return "Fog"
        case .thunderstorm: return "Thunderstorm"
        }
    }

    public var symbolName: String {
        switch self {
        case .clear: return "sun.max"
        case .partlyCloudy: return "cloud.sun"
        case .cloudy: return "cloud"
        case .rain: return "cloud.rain"
        case .snow: return "cloud.snow"
        case .wind: return "wind"
        case .fog: return "cloud.fog"
        case .thunderstorm: return "cloud.bolt.rain"
        }
    }
}

/// A fictional current-conditions observation for one location.
public struct Weather: Equatable, Sendable, Identifiable {
    public var locationId: String
    public var observedAt: Date
    public var temperature: MeasurementValue
    public var feelsLike: MeasurementValue
    public var high: MeasurementValue
    public var low: MeasurementValue
    public var condition: WeatherCondition
    public var humidity: MeasurementValue
    public var windSpeed: MeasurementValue
    public var precipitationProbability: MeasurementValue
    public var isMockData: Bool

    public init(
        locationId: String,
        observedAt: Date,
        temperature: MeasurementValue,
        feelsLike: MeasurementValue,
        high: MeasurementValue,
        low: MeasurementValue,
        condition: WeatherCondition,
        humidity: MeasurementValue,
        windSpeed: MeasurementValue,
        precipitationProbability: MeasurementValue,
        isMockData: Bool
    ) {
        self.locationId = locationId
        self.observedAt = observedAt
        self.temperature = temperature
        self.feelsLike = feelsLike
        self.high = high
        self.low = low
        self.condition = condition
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.precipitationProbability = precipitationProbability
        self.isMockData = isMockData
    }

    public var id: String { locationId }
}

public struct HourlyForecast: Equatable, Sendable, Identifiable {
    public var id: String
    public var locationId: String
    public var dateTime: Date
    public var temperature: MeasurementValue
    public var condition: WeatherCondition
    public var precipitationProbability: MeasurementValue
    public var isMockData: Bool

    public init(
        id: String,
        locationId: String,
        dateTime: Date,
        temperature: MeasurementValue,
        condition: WeatherCondition,
        precipitationProbability: MeasurementValue,
        isMockData: Bool
    ) {
        self.id = id
        self.locationId = locationId
        self.dateTime = dateTime
        self.temperature = temperature
        self.condition = condition
        self.precipitationProbability = precipitationProbability
        self.isMockData = isMockData
    }
}

public struct ForecastDay: Equatable, Sendable, Identifiable {
    public var id: String
    public var locationId: String
    public var date: Date
    public var high: MeasurementValue
    public var low: MeasurementValue
    public var condition: WeatherCondition
    public var precipitationProbability: MeasurementValue
    public var isMockData: Bool

    public init(
        id: String,
        locationId: String,
        date: Date,
        high: MeasurementValue,
        low: MeasurementValue,
        condition: WeatherCondition,
        precipitationProbability: MeasurementValue,
        isMockData: Bool
    ) {
        self.id = id
        self.locationId = locationId
        self.date = date
        self.high = high
        self.low = low
        self.condition = condition
        self.precipitationProbability = precipitationProbability
        self.isMockData = isMockData
    }
}
