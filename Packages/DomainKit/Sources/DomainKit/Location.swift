import Foundation

/// A supported Utah community in the sample catalog.
public struct Location: Equatable, Sendable, Identifiable, Hashable {
    public var id: String
    public var name: String
    public var city: String
    public var state: String
    public var postalCode: String?
    public var latitude: Double
    public var longitude: Double
    public var timezoneIdentifier: String
    public var isDefault: Bool

    public init(
        id: String,
        name: String,
        city: String,
        state: String,
        postalCode: String?,
        latitude: Double,
        longitude: Double,
        timezoneIdentifier: String,
        isDefault: Bool
    ) {
        self.id = id
        self.name = name
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.latitude = latitude
        self.longitude = longitude
        self.timezoneIdentifier = timezoneIdentifier
        self.isDefault = isDefault
    }

    public var timeZone: TimeZone {
        TimeZone(identifier: timezoneIdentifier) ?? .gmt
    }

    public var displayName: String {
        "\(city), \(state)"
    }
}

public struct MeasurementValue: Equatable, Sendable, Hashable {
    public var value: Double
    public var unitSymbol: String

    public init(value: Double, unitSymbol: String) {
        self.value = value
        self.unitSymbol = unitSymbol
    }

    public var display: String {
        if unitSymbol == "%" {
            return "\(Int(value.rounded()))%"
        }
        let rounded = value.rounded()
        if abs(rounded - value) < 0.05 {
            return "\(Int(rounded))\(unitSymbol)"
        }
        return String(format: "%.1f%@", value, unitSymbol)
    }
}
