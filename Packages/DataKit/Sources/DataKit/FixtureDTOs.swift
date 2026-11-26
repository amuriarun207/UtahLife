import CoreKit
import DomainKit
import Foundation

struct MeasurementDTO: Decodable {
    var value: Double
    var unitSymbol: String

    var model: MeasurementValue {
        MeasurementValue(value: value, unitSymbol: unitSymbol)
    }
}

struct LocationDTO: Decodable {
    var id: String
    var name: String
    var city: String
    var state: String
    var postalCode: String?
    var latitude: Double
    var longitude: Double
    var timezoneIdentifier: String
    var isDefault: Bool

    var model: Location {
        Location(
            id: id,
            name: name,
            city: city,
            state: state,
            postalCode: postalCode,
            latitude: latitude,
            longitude: longitude,
            timezoneIdentifier: timezoneIdentifier,
            isDefault: isDefault
        )
    }
}

struct WeatherDTO: Decodable {
    var locationId: String
    var observedAt: String
    var temperature: MeasurementDTO
    var feelsLike: MeasurementDTO
    var high: MeasurementDTO
    var low: MeasurementDTO
    var condition: String
    var humidity: MeasurementDTO
    var windSpeed: MeasurementDTO
    var precipitationProbability: MeasurementDTO
    var isMockData: Bool

    func model() throws -> Weather {
        guard let parsed = WeatherCondition(rawValue: condition) else {
            throw AppError.decoding("Unknown weather condition \(condition).")
        }
        return Weather(
            locationId: locationId,
            observedAt: try SampleDateParser.date(from: observedAt),
            temperature: temperature.model,
            feelsLike: feelsLike.model,
            high: high.model,
            low: low.model,
            condition: parsed,
            humidity: humidity.model,
            windSpeed: windSpeed.model,
            precipitationProbability: precipitationProbability.model,
            isMockData: isMockData
        )
    }
}

struct HourlyForecastDTO: Decodable {
    var id: String
    var locationId: String
    var dateTime: String
    var temperature: MeasurementDTO
    var condition: String
    var precipitationProbability: MeasurementDTO
    var isMockData: Bool

    func model() throws -> HourlyForecast {
        guard let parsed = WeatherCondition(rawValue: condition) else {
            throw AppError.decoding("Unknown weather condition \(condition).")
        }
        return HourlyForecast(
            id: id,
            locationId: locationId,
            dateTime: try SampleDateParser.date(from: dateTime),
            temperature: temperature.model,
            condition: parsed,
            precipitationProbability: precipitationProbability.model,
            isMockData: isMockData
        )
    }
}

struct ForecastDayDTO: Decodable {
    var id: String
    var locationId: String
    var date: String
    var high: MeasurementDTO
    var low: MeasurementDTO
    var condition: String
    var precipitationProbability: MeasurementDTO
    var isMockData: Bool

    func model() throws -> ForecastDay {
        guard let parsed = WeatherCondition(rawValue: condition) else {
            throw AppError.decoding("Unknown weather condition \(condition).")
        }
        return ForecastDay(
            id: id,
            locationId: locationId,
            date: try SampleDateParser.date(from: date),
            high: high.model,
            low: low.model,
            condition: parsed,
            precipitationProbability: precipitationProbability.model,
            isMockData: isMockData
        )
    }
}

struct AirQualityDTO: Decodable {
    var locationId: String
    var observedAt: String
    var aqi: Int
    var category: String
    var primaryPollutant: String
    var sourceLabel: String
    var isMockData: Bool

    func model() throws -> AirQuality {
        guard let parsed = AQICategory(rawValue: category) else {
            throw AppError.decoding("Unknown air-quality category \(category).")
        }
        return AirQuality(
            locationId: locationId,
            observedAt: try SampleDateParser.date(from: observedAt),
            aqi: aqi,
            category: parsed,
            primaryPollutant: primaryPollutant,
            sourceLabel: sourceLabel,
            isMockData: isMockData
        )
    }
}

struct TrafficIncidentDTO: Decodable {
    var id: String
    var locationId: String
    var title: String
    var description: String
    var road: String
    var area: String
    var severity: String
    var incidentType: String
    var status: String
    var latitude: Double
    var longitude: Double
    var reportedAt: String
    var updatedAt: String
    var isMockData: Bool

    func model() throws -> TrafficIncident {
        guard let severity = IncidentSeverity(rawValue: severity),
              let incidentType = IncidentType(rawValue: incidentType),
              let status = IncidentStatus(rawValue: status) else {
            throw AppError.decoding("Unknown incident classification for \(id).")
        }
        return TrafficIncident(
            id: id,
            locationId: locationId,
            title: title,
            description: description,
            road: road,
            area: area,
            severity: severity,
            incidentType: incidentType,
            status: status,
            latitude: latitude,
            longitude: longitude,
            reportedAt: try SampleDateParser.date(from: reportedAt),
            updatedAt: try SampleDateParser.date(from: updatedAt),
            isMockData: isMockData
        )
    }
}

struct RoadConditionDTO: Decodable {
    var id: String
    var locationId: String
    var roadName: String
    var area: String
    var condition: String
    var description: String
    var updatedAt: String
    var isMockData: Bool

    func model() throws -> RoadCondition {
        guard let condition = RoadSurfaceCondition(rawValue: condition) else {
            throw AppError.decoding("Unknown road condition \(condition).")
        }
        return RoadCondition(
            id: id,
            locationId: locationId,
            roadName: roadName,
            area: area,
            condition: condition,
            description: description,
            updatedAt: try SampleDateParser.date(from: updatedAt),
            isMockData: isMockData
        )
    }
}

struct LocalPlaceDTO: Decodable {
    var id: String
    var locationId: String
    var name: String
    var category: String
    var address: String
    var latitude: Double
    var longitude: Double
    var description: String
    var isMockData: Bool

    func model() throws -> LocalPlace {
        guard let category = PlaceCategory(rawValue: category) else {
            throw AppError.decoding("Unknown place category \(category).")
        }
        return LocalPlace(
            id: id,
            locationId: locationId,
            name: name,
            category: category,
            address: address,
            latitude: latitude,
            longitude: longitude,
            description: description,
            isMockData: isMockData
        )
    }
}

struct LocalAlertDTO: Decodable {
    var id: String
    var locationId: String
    var title: String
    var summary: String
    var details: String
    var category: String
    var severity: String
    var area: String
    var createdAt: String
    var expiresAt: String?
    var isRead: Bool
    var isMockData: Bool

    func model() throws -> LocalAlert {
        guard let category = AlertCategory(rawValue: category),
              let severity = AlertSeverity(rawValue: severity) else {
            throw AppError.decoding("Unknown alert classification for \(id).")
        }
        let expiry: Date?
        if let expiresAt {
            expiry = try SampleDateParser.date(from: expiresAt)
        } else {
            expiry = nil
        }
        return LocalAlert(
            id: id,
            locationId: locationId,
            title: title,
            summary: summary,
            details: details,
            category: category,
            severity: severity,
            area: area,
            createdAt: try SampleDateParser.date(from: createdAt),
            expiresAt: expiry,
            isRead: isRead,
            isMockData: isMockData
        )
    }
}

struct SavedCommuteDTO: Decodable {
    var id: String
    var locationId: String
    var name: String
    var origin: String
    var destination: String
    var sampleNote: String

    var model: SavedCommute {
        SavedCommute(
            id: id,
            locationId: locationId,
            name: name,
            origin: origin,
            destination: destination,
            sampleNote: sampleNote
        )
    }
}

struct MockCameraDTO: Decodable {
    var id: String
    var locationId: String
    var name: String
    var road: String
    var area: String
    var sampleStatus: String

    var model: MockCamera {
        MockCamera(
            id: id,
            locationId: locationId,
            name: name,
            road: road,
            area: area,
            sampleStatus: sampleStatus
        )
    }
}
