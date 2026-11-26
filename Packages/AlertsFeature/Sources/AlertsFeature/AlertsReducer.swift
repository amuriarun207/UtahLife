import CoreKit
import DomainKit

public struct AlertsState: Equatable {
    public var selectedLocation: Location
    public var locations: [Location]
    public var alerts: AsyncValue<[LocalAlert]>
    public var visibleAlerts: [LocalAlert]
    public var categories: Set<AlertCategory>
    public var severities: Set<AlertSeverity>
    public var selectedAlertID: String?
    public var pendingAlertID: String?
    public var preferences: NotificationPreferences
    public var isPreferencesPresented: Bool
    public var isRefreshing: Bool

    public init(
        selectedLocation: Location,
        locations: [Location],
        alerts: AsyncValue<[LocalAlert]> = .idle,
        visibleAlerts: [LocalAlert] = [],
        categories: Set<AlertCategory> = [],
        severities: Set<AlertSeverity> = [],
        selectedAlertID: String? = nil,
        pendingAlertID: String? = nil,
        preferences: NotificationPreferences = .sampleDefault,
        isPreferencesPresented: Bool = false,
        isRefreshing: Bool = false
    ) {
        self.selectedLocation = selectedLocation
        self.locations = locations
        self.alerts = alerts
        self.visibleAlerts = visibleAlerts
        self.categories = categories
        self.severities = severities
        self.selectedAlertID = selectedAlertID
        self.pendingAlertID = pendingAlertID
        self.preferences = preferences
        self.isPreferencesPresented = isPreferencesPresented
        self.isRefreshing = isRefreshing
    }
}

public enum AlertsIntent: Equatable, Sendable {
    case onAppear
    case refresh
    case retry
    case selectLocation(Location)
    case toggleCategory(AlertCategory)
    case toggleSeverity(AlertSeverity)
    case clearFilters
    case selectAlert(String?)
    case openAlert(String)
    case markRead(String)
    case markAllRead
    case showPreferences
    case dismissPreferences
    case setMasterEnabled(Bool)
    case setCategoryEnabled(AlertCategory, Bool)
}

public enum AlertsAction: Equatable, Sendable {
    case loadStarted
    case refreshStarted
    case loaded([LocalAlert])
    case failed(AppError)
    case empty
    case locationChanged(Location)
    case filters(Set<AlertCategory>, Set<AlertSeverity>)
    case selected(String?)
    case pending(String?)
    case preferences(NotificationPreferences, presented: Bool)
}

public enum AlertsReducer {
    public static func reduce(_ state: AlertsState, _ action: AlertsAction) -> AlertsState {
        var state = state
        switch action {
        case .loadStarted:
            state.alerts = .loading
            state.visibleAlerts = []
            state.isRefreshing = false
        case .refreshStarted:
            state.isRefreshing = true
        case let .loaded(alerts):
            state.alerts = alerts.isEmpty ? .empty : .loaded(alerts)
            state.visibleAlerts = visible(alerts, state: state)
            state.isRefreshing = false
            if let pending = state.pendingAlertID, alerts.contains(where: { $0.id == pending }) {
                state.selectedAlertID = pending
                state.pendingAlertID = nil
            }
        case let .failed(error):
            state.alerts = .failed(error)
            state.visibleAlerts = []
            state.isRefreshing = false
        case .empty:
            state.alerts = .empty
            state.visibleAlerts = []
            state.isRefreshing = false
        case let .locationChanged(location):
            state.selectedLocation = location
            state.selectedAlertID = nil
        case let .filters(categories, severities):
            state.categories = categories
            state.severities = severities
            state.visibleAlerts = visible(state.alerts.value ?? [], state: state)
        case let .selected(id):
            state.selectedAlertID = id
        case let .pending(id):
            state.pendingAlertID = id
            if let id, state.alerts.value?.contains(where: { $0.id == id }) == true {
                state.selectedAlertID = id
                state.pendingAlertID = nil
            }
        case let .preferences(preferences, presented):
            state.preferences = preferences
            state.isPreferencesPresented = presented
        }
        return state
    }

    private static func visible(_ alerts: [LocalAlert], state: AlertsState) -> [LocalAlert] {
        FilterLocalAlertsUseCase.apply(
            alerts,
            query: FilterLocalAlertsUseCase.Query(categories: state.categories, severities: state.severities)
        )
    }
}
