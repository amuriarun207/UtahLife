import Foundation

public enum AlertCategory: String, Equatable, Sendable, CaseIterable, Identifiable, Codable {
    case weather
    case snow
    case roadClosure
    case traffic
    case airQuality
    case community
    case publicService

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .weather: return "Weather"
        case .snow: return "Snow and winter"
        case .roadClosure: return "Road closure"
        case .traffic: return "Traffic"
        case .airQuality: return "Air quality"
        case .community: return "Community"
        case .publicService: return "Public service"
        }
    }

    public var symbolName: String {
        switch self {
        case .weather: return "cloud.sun"
        case .snow: return "snowflake"
        case .roadClosure: return "road.lanes"
        case .traffic: return "car"
        case .airQuality: return "aqi.medium"
        case .community: return "person.3"
        case .publicService: return "building.2"
        }
    }
}

public enum AlertSeverity: String, Equatable, Sendable, CaseIterable, Comparable {
    case info
    case advisory
    case warning
    case critical

    public var title: String {
        switch self {
        case .info: return "Info"
        case .advisory: return "Advisory"
        case .warning: return "Warning"
        case .critical: return "Critical"
        }
    }

    public var symbolName: String {
        switch self {
        case .info: return "info.circle"
        case .advisory: return "exclamationmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .critical: return "exclamationmark.octagon"
        }
    }

    public var rank: Int {
        switch self {
        case .info: return 0
        case .advisory: return 1
        case .warning: return 2
        case .critical: return 3
        }
    }

    public static func < (lhs: AlertSeverity, rhs: AlertSeverity) -> Bool {
        lhs.rank < rhs.rank
    }
}

public struct LocalAlert: Equatable, Sendable, Identifiable, Hashable {
    public var id: String
    public var locationId: String
    public var title: String
    public var summary: String
    public var details: String
    public var category: AlertCategory
    public var severity: AlertSeverity
    public var area: String
    public var createdAt: Date
    public var expiresAt: Date?
    public var isRead: Bool
    public var isMockData: Bool

    public init(
        id: String,
        locationId: String,
        title: String,
        summary: String,
        details: String,
        category: AlertCategory,
        severity: AlertSeverity,
        area: String,
        createdAt: Date,
        expiresAt: Date?,
        isRead: Bool,
        isMockData: Bool
    ) {
        self.id = id
        self.locationId = locationId
        self.title = title
        self.summary = summary
        self.details = details
        self.category = category
        self.severity = severity
        self.area = area
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.isRead = isRead
        self.isMockData = isMockData
    }
}

public struct NotificationPreferences: Equatable, Sendable, Codable {
    public var masterEnabled: Bool
    public var categories: [AlertCategory: Bool]

    public init(masterEnabled: Bool, categories: [AlertCategory: Bool]) {
        self.masterEnabled = masterEnabled
        self.categories = categories
    }

    public static var sampleDefault: NotificationPreferences {
        let categories = Dictionary(uniqueKeysWithValues: AlertCategory.allCases.map { ($0, true) })
        return NotificationPreferences(masterEnabled: false, categories: categories)
    }

    public func isEnabled(_ category: AlertCategory) -> Bool {
        guard masterEnabled else { return false }
        return categories[category] ?? false
    }
}

public enum EnvironmentFocus: String, Equatable, Sendable, CaseIterable {
    case weather
    case airQuality

    public var title: String {
        switch self {
        case .weather: return "Weather"
        case .airQuality: return "Air quality"
        }
    }
}
