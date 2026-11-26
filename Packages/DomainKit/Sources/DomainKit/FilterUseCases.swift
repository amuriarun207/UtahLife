import CoreKit
import Foundation

public struct FilterTrafficIncidentsUseCase: Sendable {
    public struct Query: Equatable, Sendable {
        public var severities: Set<IncidentSeverity>
        public var types: Set<IncidentType>

        public init(severities: Set<IncidentSeverity>, types: Set<IncidentType>) {
            self.severities = severities
            self.types = types
        }
    }

    public init() {}

    public func execute(_ incidents: [TrafficIncident], query: Query) -> [TrafficIncident] {
        Self.apply(incidents, query: query)
    }

    public static func apply(_ incidents: [TrafficIncident], query: Query) -> [TrafficIncident] {
        incidents
            .filter { incident in
                let severityMatches = query.severities.isEmpty || query.severities.contains(incident.severity)
                let typeMatches = query.types.isEmpty || query.types.contains(incident.incidentType)
                return severityMatches && typeMatches
            }
            .sorted(by: isOrderedBefore)
    }

    public static func isOrderedBefore(_ lhs: TrafficIncident, _ rhs: TrafficIncident) -> Bool {
        if lhs.severity != rhs.severity {
            return lhs.severity > rhs.severity
        }
        if lhs.updatedAt != rhs.updatedAt {
            return lhs.updatedAt > rhs.updatedAt
        }
        return lhs.id < rhs.id
    }
}

public struct FilterLocalAlertsUseCase: Sendable {
    public struct Query: Equatable, Sendable {
        public var categories: Set<AlertCategory>
        public var severities: Set<AlertSeverity>

        public init(categories: Set<AlertCategory>, severities: Set<AlertSeverity>) {
            self.categories = categories
            self.severities = severities
        }
    }

    public init() {}

    public func execute(_ alerts: [LocalAlert], query: Query) -> [LocalAlert] {
        Self.apply(alerts, query: query)
    }

    public static func apply(_ alerts: [LocalAlert], query: Query) -> [LocalAlert] {
        alerts
            .filter { alert in
                let categoryMatches = query.categories.isEmpty || query.categories.contains(alert.category)
                let severityMatches = query.severities.isEmpty || query.severities.contains(alert.severity)
                return categoryMatches && severityMatches
            }
            .sorted { lhs, rhs in
                if lhs.isRead != rhs.isRead {
                    return lhs.isRead == false && rhs.isRead == true
                }
                if lhs.createdAt != rhs.createdAt {
                    return lhs.createdAt > rhs.createdAt
                }
                return lhs.id < rhs.id
            }
    }
}

public struct SearchLocalPlacesUseCase: Sendable {
    public struct Query: Equatable, Sendable {
        public var text: String
        public var category: PlaceCategory?

        public init(text: String, category: PlaceCategory?) {
            self.text = text
            self.category = category
        }
    }

    private let repository: any LocalPlacesRepositoryProtocol

    public init(repository: any LocalPlacesRepositoryProtocol) {
        self.repository = repository
    }

    public func load(location: Location, query: Query) async throws -> [LocalPlace] {
        let places = try await repository.places(near: location)
        return Self.filter(places, near: location, query: query)
    }

    public static func filter(_ places: [LocalPlace], near location: Location, query: Query) -> [LocalPlace] {
        let trimmed = query.text.trimmingCharacters(in: .whitespacesAndNewlines)
        return places
            .filter { place in
                if let category = query.category, place.category != category {
                    return false
                }
                guard trimmed.isEmpty == false else { return true }
                let haystack = "\(place.name) \(place.category.title) \(place.address)".lowercased()
                return haystack.contains(trimmed.lowercased())
            }
            .sorted { lhs, rhs in
                let left = DistanceCalculator.miles(
                    fromLatitude: location.latitude,
                    fromLongitude: location.longitude,
                    toLatitude: lhs.latitude,
                    toLongitude: lhs.longitude
                )
                let right = DistanceCalculator.miles(
                    fromLatitude: location.latitude,
                    fromLongitude: location.longitude,
                    toLatitude: rhs.latitude,
                    toLongitude: rhs.longitude
                )
                if abs(left - right) > 0.01 {
                    return left < right
                }
                return lhs.name < rhs.name
            }
    }
}

public struct LoadAlertsUseCase: Sendable {
    private let repository: any AlertsRepositoryProtocol

    public init(repository: any AlertsRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(location: Location) async throws -> [LocalAlert] {
        let alerts = try await repository.alerts(for: location)
        return FilterLocalAlertsUseCase.apply(
            alerts,
            query: FilterLocalAlertsUseCase.Query(categories: [], severities: [])
        )
    }
}

public struct MarkAlertAsReadUseCase: Sendable {
    private let repository: any AlertsRepositoryProtocol

    public init(repository: any AlertsRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(id: String, location: Location) async throws -> [LocalAlert] {
        try await repository.markAsRead(id: id)
        let alerts = try await repository.alerts(for: location)
        return FilterLocalAlertsUseCase.apply(
            alerts,
            query: FilterLocalAlertsUseCase.Query(categories: [], severities: [])
        )
    }
}

public struct MarkAllAlertsAsReadUseCase: Sendable {
    private let repository: any AlertsRepositoryProtocol

    public init(repository: any AlertsRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(location: Location) async throws -> [LocalAlert] {
        try await repository.markAllAsRead()
        let alerts = try await repository.alerts(for: location)
        return FilterLocalAlertsUseCase.apply(
            alerts,
            query: FilterLocalAlertsUseCase.Query(categories: [], severities: [])
        )
    }
}

public struct NotificationPreferencesUseCase: Sendable {
    private let repository: any NotificationPreferencesRepositoryProtocol

    public init(repository: any NotificationPreferencesRepositoryProtocol) {
        self.repository = repository
    }

    public func load() async -> NotificationPreferences {
        await repository.load()
    }

    public func update(_ preferences: NotificationPreferences) async {
        await repository.save(preferences)
    }
}

public struct SelectLocationUseCase: Sendable {
    private let preferences: any LocationPreferencesProtocol

    public init(preferences: any LocationPreferencesProtocol) {
        self.preferences = preferences
    }

    public func execute(location: Location, available: [Location]) async throws -> Location {
        guard available.contains(where: { $0.id == location.id }) else {
            throw AppError.unavailable("That location is not in the sample list.")
        }
        await preferences.setSelectedLocationID(location.id)
        return location
    }

    public func restore(available: [Location]) async throws -> Location {
        if let savedID = await preferences.selectedLocationID(),
           let match = available.first(where: { $0.id == savedID }) {
            return match
        }
        guard let fallback = available.first(where: \.isDefault) ?? available.first else {
            throw AppError.empty("No sample locations are available.")
        }
        return fallback
    }
}
