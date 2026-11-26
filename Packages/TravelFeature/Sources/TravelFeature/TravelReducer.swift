import CoreKit
import DomainKit

public enum TravelPresentation: String, Equatable, Sendable {
    case list
    case map
}

public struct TravelState: Equatable {
    public var selectedLocation: Location
    public var locations: [Location]
    public var overview: AsyncValue<TravelOverview>
    public var visibleIncidents: [TrafficIncident]
    public var severityFilter: Set<IncidentSeverity>
    public var typeFilter: Set<IncidentType>
    public var presentation: TravelPresentation
    public var selectedIncidentID: String?
    public var selectedCommuteID: String?
    public var selectedCameraID: String?
    public var isRefreshing: Bool

    public init(
        selectedLocation: Location,
        locations: [Location],
        overview: AsyncValue<TravelOverview> = .idle,
        visibleIncidents: [TrafficIncident] = [],
        severityFilter: Set<IncidentSeverity> = [],
        typeFilter: Set<IncidentType> = [],
        presentation: TravelPresentation = .list,
        selectedIncidentID: String? = nil,
        selectedCommuteID: String? = nil,
        selectedCameraID: String? = nil,
        isRefreshing: Bool = false
    ) {
        self.selectedLocation = selectedLocation
        self.locations = locations
        self.overview = overview
        self.visibleIncidents = visibleIncidents
        self.severityFilter = severityFilter
        self.typeFilter = typeFilter
        self.presentation = presentation
        self.selectedIncidentID = selectedIncidentID
        self.selectedCommuteID = selectedCommuteID
        self.selectedCameraID = selectedCameraID
        self.isRefreshing = isRefreshing
    }
}

public enum TravelIntent: Equatable, Sendable {
    case onAppear
    case refresh
    case retry
    case selectLocation(Location)
    case toggleSeverity(IncidentSeverity)
    case toggleType(IncidentType)
    case clearFilters
    case presentation(TravelPresentation)
    case selectIncident(String?)
    case selectCommute(String?)
    case selectCamera(String?)
}

public enum TravelAction: Equatable, Sendable {
    case loadStarted
    case refreshStarted
    case loaded(TravelOverview)
    case failed(AppError)
    case empty
    case locationChanged(Location)
    case filters(Set<IncidentSeverity>, Set<IncidentType>)
    case presentation(TravelPresentation)
    case incident(String?)
    case commute(String?)
    case camera(String?)
}

public enum TravelReducer {
    public static func reduce(_ state: TravelState, _ action: TravelAction) -> TravelState {
        var state = state
        switch action {
        case .loadStarted:
            state.overview = .loading
            state.visibleIncidents = []
            state.isRefreshing = false
        case .refreshStarted:
            state.isRefreshing = true
        case let .loaded(overview):
            if overview.incidents.isEmpty && overview.roadConditions.isEmpty {
                state.overview = .empty
                state.visibleIncidents = []
            } else {
                state.overview = .loaded(overview)
                state.visibleIncidents = visible(overview: overview, state: state)
            }
            state.isRefreshing = false
        case let .failed(error):
            state.overview = .failed(error)
            state.visibleIncidents = []
            state.isRefreshing = false
        case .empty:
            state.overview = .empty
            state.visibleIncidents = []
            state.isRefreshing = false
        case let .locationChanged(location):
            state.selectedLocation = location
            state.selectedIncidentID = nil
        case let .filters(severities, types):
            state.severityFilter = severities
            state.typeFilter = types
            state.visibleIncidents = visible(overview: state.overview.value, state: state)
        case let .presentation(presentation):
            state.presentation = presentation
        case let .incident(id):
            state.selectedIncidentID = id
        case let .commute(id):
            state.selectedCommuteID = id
        case let .camera(id):
            state.selectedCameraID = id
        }
        return state
    }

    private static func visible(overview: TravelOverview?, state: TravelState) -> [TrafficIncident] {
        guard let overview else { return [] }
        return FilterTrafficIncidentsUseCase.apply(
            overview.incidents,
            query: FilterTrafficIncidentsUseCase.Query(severities: state.severityFilter, types: state.typeFilter)
        )
    }
}
