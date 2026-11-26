import CoreKit
import DomainKit

public struct EnvironmentState: Equatable {
    public var selectedLocation: Location
    public var locations: [Location]
    public var section: EnvironmentFocus
    public var snapshot: AsyncValue<EnvironmentSnapshot>
    public var selectedDayID: String?
    public var isAQIExpanded: Bool
    public var isRefreshing: Bool
    public var isLocationPickerPresented: Bool

    public init(
        selectedLocation: Location,
        locations: [Location],
        section: EnvironmentFocus = .weather,
        snapshot: AsyncValue<EnvironmentSnapshot> = .idle,
        selectedDayID: String? = nil,
        isAQIExpanded: Bool = false,
        isRefreshing: Bool = false,
        isLocationPickerPresented: Bool = false
    ) {
        self.selectedLocation = selectedLocation
        self.locations = locations
        self.section = section
        self.snapshot = snapshot
        self.selectedDayID = selectedDayID
        self.isAQIExpanded = isAQIExpanded
        self.isRefreshing = isRefreshing
        self.isLocationPickerPresented = isLocationPickerPresented
    }
}

public enum EnvironmentIntent: Equatable, Sendable {
    case onAppear
    case refresh
    case retry
    case selectLocation(Location)
    case selectSection(EnvironmentFocus)
    case selectDay(String)
    case toggleAQIExplanation
    case showLocationPicker
    case dismissLocationPicker
    case focus(EnvironmentFocus)
}

public enum EnvironmentAction: Equatable, Sendable {
    case loadStarted
    case refreshStarted
    case loaded(EnvironmentSnapshot)
    case failed(AppError)
    case empty
    case locationChanged(Location)
    case section(EnvironmentFocus)
    case day(String)
    case aqiExpanded(Bool)
    case presentLocationPicker(Bool)
}

public enum EnvironmentReducer {
    public static func reduce(_ state: EnvironmentState, _ action: EnvironmentAction) -> EnvironmentState {
        var state = state
        switch action {
        case .loadStarted:
            state.snapshot = .loading
            state.isRefreshing = false
        case .refreshStarted:
            state.isRefreshing = true
        case let .loaded(snapshot):
            state.snapshot = .loaded(snapshot)
            state.isRefreshing = false
            state.isLocationPickerPresented = false
            if state.selectedDayID == nil {
                state.selectedDayID = snapshot.daily.first?.id
            }
        case let .failed(error):
            state.snapshot = .failed(error)
            state.isRefreshing = false
        case .empty:
            state.snapshot = .empty
            state.isRefreshing = false
        case let .locationChanged(location):
            state.selectedLocation = location
            state.selectedDayID = nil
            state.isLocationPickerPresented = false
        case let .section(section):
            state.section = section
        case let .day(id):
            state.selectedDayID = id
        case let .aqiExpanded(isExpanded):
            state.isAQIExpanded = isExpanded
        case let .presentLocationPicker(isPresented):
            state.isLocationPickerPresented = isPresented
        }
        return state
    }
}
