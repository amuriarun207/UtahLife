import Foundation

public enum IncidentSeverity: String, Equatable, Sendable, CaseIterable, Comparable {
    case low
    case moderate
    case high
    case critical

    public var title: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }

    public var symbolName: String {
        switch self {
        case .low: return "info.circle"
        case .moderate: return "exclamationmark.circle"
        case .high: return "exclamationmark.triangle"
        case .critical: return "exclamationmark.octagon"
        }
    }

    public var rank: Int {
        switch self {
        case .low: return 0
        case .moderate: return 1
        case .high: return 2
        case .critical: return 3
        }
    }

    public static func < (lhs: IncidentSeverity, rhs: IncidentSeverity) -> Bool {
        lhs.rank < rhs.rank
    }
}

public enum IncidentType: String, Equatable, Sendable, CaseIterable {
    case congestion
    case roadwork
    case closure
    case weather
    case crash

    public var title: String {
        switch self {
        case .congestion: return "Congestion"
        case .roadwork: return "Roadwork"
        case .closure: return "Closure"
        case .weather: return "Weather"
        case .crash: return "Crash"
        }
    }

    public var symbolName: String {
        switch self {
        case .congestion: return "car.2"
        case .roadwork: return "cone"
        case .closure: return "road.lanes"
        case .weather: return "cloud.snow"
        case .crash: return "car.side"
        }
    }
}

public enum IncidentStatus: String, Equatable, Sendable {
    case active
    case cleared
    case scheduled

    public var title: String {
        switch self {
        case .active: return "Active"
        case .cleared: return "Cleared"
        case .scheduled: return "Scheduled"
        }
    }
}

public struct TrafficIncident: Equatable, Sendable, Identifiable, Hashable {
    public var id: String
    public var locationId: String
    public var title: String
    public var description: String
    public var road: String
    public var area: String
    public var severity: IncidentSeverity
    public var incidentType: IncidentType
    public var status: IncidentStatus
    public var latitude: Double
    public var longitude: Double
    public var reportedAt: Date
    public var updatedAt: Date
    public var isMockData: Bool

    public init(
        id: String,
        locationId: String,
        title: String,
        description: String,
        road: String,
        area: String,
        severity: IncidentSeverity,
        incidentType: IncidentType,
        status: IncidentStatus,
        latitude: Double,
        longitude: Double,
        reportedAt: Date,
        updatedAt: Date,
        isMockData: Bool
    ) {
        self.id = id
        self.locationId = locationId
        self.title = title
        self.description = description
        self.road = road
        self.area = area
        self.severity = severity
        self.incidentType = incidentType
        self.status = status
        self.latitude = latitude
        self.longitude = longitude
        self.reportedAt = reportedAt
        self.updatedAt = updatedAt
        self.isMockData = isMockData
    }
}

public enum RoadSurfaceCondition: String, Equatable, Sendable, CaseIterable {
    case clear
    case wet
    case icy
    case snowCovered
    case construction

    public var title: String {
        switch self {
        case .clear: return "Clear"
        case .wet: return "Wet"
        case .icy: return "Icy"
        case .snowCovered: return "Snow covered"
        case .construction: return "Construction"
        }
    }

    public var symbolName: String {
        switch self {
        case .clear: return "checkmark.circle"
        case .wet: return "drop"
        case .icy: return "snowflake"
        case .snowCovered: return "snowflake"
        case .construction: return "cone"
        }
    }
}

public struct RoadCondition: Equatable, Sendable, Identifiable, Hashable {
    public var id: String
    public var locationId: String
    public var roadName: String
    public var area: String
    public var condition: RoadSurfaceCondition
    public var description: String
    public var updatedAt: Date
    public var isMockData: Bool

    public init(
        id: String,
        locationId: String,
        roadName: String,
        area: String,
        condition: RoadSurfaceCondition,
        description: String,
        updatedAt: Date,
        isMockData: Bool
    ) {
        self.id = id
        self.locationId = locationId
        self.roadName = roadName
        self.area = area
        self.condition = condition
        self.description = description
        self.updatedAt = updatedAt
        self.isMockData = isMockData
    }
}

public struct TrafficSummary: Equatable, Sendable {
    public var headline: String
    public var incidentCount: Int
    public var highestSeverity: IncidentSeverity?
    public var topIncidents: [TrafficIncident]
    public var roadConditionHeadline: String

    public init(
        headline: String,
        incidentCount: Int,
        highestSeverity: IncidentSeverity?,
        topIncidents: [TrafficIncident],
        roadConditionHeadline: String
    ) {
        self.headline = headline
        self.incidentCount = incidentCount
        self.highestSeverity = highestSeverity
        self.topIncidents = topIncidents
        self.roadConditionHeadline = roadConditionHeadline
    }
}

public struct SavedCommute: Equatable, Sendable, Identifiable, Hashable {
    public var id: String
    public var locationId: String
    public var name: String
    public var origin: String
    public var destination: String
    public var sampleNote: String

    public init(
        id: String,
        locationId: String,
        name: String,
        origin: String,
        destination: String,
        sampleNote: String
    ) {
        self.id = id
        self.locationId = locationId
        self.name = name
        self.origin = origin
        self.destination = destination
        self.sampleNote = sampleNote
    }
}

public struct MockCamera: Equatable, Sendable, Identifiable, Hashable {
    public var id: String
    public var locationId: String
    public var name: String
    public var road: String
    public var area: String
    public var sampleStatus: String

    public init(
        id: String,
        locationId: String,
        name: String,
        road: String,
        area: String,
        sampleStatus: String
    ) {
        self.id = id
        self.locationId = locationId
        self.name = name
        self.road = road
        self.area = area
        self.sampleStatus = sampleStatus
    }
}
