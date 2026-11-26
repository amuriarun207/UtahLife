import Foundation

/// EPA-style breakpoints applied to sample AQI values.
public enum AQICategory: String, Equatable, Sendable, CaseIterable {
    case good
    case moderate
    case unhealthyForSensitiveGroups
    case unhealthy
    case veryUnhealthy
    case hazardous

    public var title: String {
        switch self {
        case .good: return "Good"
        case .moderate: return "Moderate"
        case .unhealthyForSensitiveGroups: return "Unhealthy for sensitive groups"
        case .unhealthy: return "Unhealthy"
        case .veryUnhealthy: return "Very unhealthy"
        case .hazardous: return "Hazardous"
        }
    }

    public var symbolName: String {
        switch self {
        case .good: return "leaf"
        case .moderate: return "aqi.medium"
        case .unhealthyForSensitiveGroups: return "aqi.medium"
        case .unhealthy: return "aqi.high"
        case .veryUnhealthy: return "aqi.high"
        case .hazardous: return "exclamationmark.triangle"
        }
    }

    public var explanation: String {
        switch self {
        case .good:
            return "Sample index 0–50. Air quality is described as satisfactory for this fixture."
        case .moderate:
            return "Sample index 51–100. The fixture describes acceptable air with a possible concern for unusually sensitive people."
        case .unhealthyForSensitiveGroups:
            return "Sample index 101–150. The fixture says sensitive groups may notice effects."
        case .unhealthy:
            return "Sample index 151–200. The fixture describes air that may affect the general population."
        case .veryUnhealthy:
            return "Sample index 201–300. The fixture describes a health warning of emergency conditions."
        case .hazardous:
            return "Sample index above 300. The fixture describes hazardous air. This is not a live reading."
        }
    }

    public var guidance: String {
        switch self {
        case .good:
            return "Sample note: outdoor activity is described as comfortable in this fixture."
        case .moderate:
            return "Sample note: unusually sensitive people may want to limit prolonged outdoor exertion."
        case .unhealthyForSensitiveGroups:
            return "Sample note: people with heart or lung conditions, older adults, and children may want shorter outdoor exertion."
        case .unhealthy:
            return "Sample note: everyone may want to reduce prolonged outdoor exertion."
        case .veryUnhealthy:
            return "Sample note: everyone may want to avoid prolonged outdoor exertion."
        case .hazardous:
            return "Sample note: everyone may want to stay indoors. This wording is informational only."
        }
    }

    public static func category(for aqi: Int) -> AQICategory {
        switch aqi {
        case ...50:
            return .good
        case 51...100:
            return .moderate
        case 101...150:
            return .unhealthyForSensitiveGroups
        case 151...200:
            return .unhealthy
        case 201...300:
            return .veryUnhealthy
        default:
            return .hazardous
        }
    }
}

public struct AirQuality: Equatable, Sendable, Identifiable {
    public var locationId: String
    public var observedAt: Date
    public var aqi: Int
    public var category: AQICategory
    public var primaryPollutant: String
    public var sourceLabel: String
    public var isMockData: Bool

    public init(
        locationId: String,
        observedAt: Date,
        aqi: Int,
        category: AQICategory,
        primaryPollutant: String,
        sourceLabel: String,
        isMockData: Bool
    ) {
        self.locationId = locationId
        self.observedAt = observedAt
        self.aqi = aqi
        self.category = category
        self.primaryPollutant = primaryPollutant
        self.sourceLabel = sourceLabel
        self.isMockData = isMockData
    }

    public var id: String { locationId }

    public func applyingDerivedCategory() -> AirQuality {
        var copy = self
        copy.category = AQICategory.category(for: aqi)
        copy.isMockData = true
        return copy
    }
}
