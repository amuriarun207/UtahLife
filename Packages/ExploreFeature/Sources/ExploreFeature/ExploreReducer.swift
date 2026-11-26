import CoreKit
import DomainKit

public enum ExplorePresentation: String, Equatable, Sendable {
    case list
    case map
}

public struct ExploreState: Equatable {
    public var selectedLocation: Location
    public var locations: [Location]
    public var places: AsyncValue<[LocalPlace]>
    public var visiblePlaces: [LocalPlace]
    public var query: String
    public var category: PlaceCategory?
    public var presentation: ExplorePresentation
    public var highlightedPlaceID: String?
    public var selectedPlaceID: String?
    public var isRefreshing: Bool
    public var isLocationPickerPresented: Bool

    public init(
        selectedLocation: Location,
        locations: [Location],
        places: AsyncValue<[LocalPlace]> = .idle,
        visiblePlaces: [LocalPlace] = [],
        query: String = "",
        category: PlaceCategory? = nil,
        presentation: ExplorePresentation = .list,
        highlightedPlaceID: String? = nil,
        selectedPlaceID: String? = nil,
        isRefreshing: Bool = false,
        isLocationPickerPresented: Bool = false
    ) {
        self.selectedLocation = selectedLocation
        self.locations = locations
        self.places = places
        self.visiblePlaces = visiblePlaces
        self.query = query
        self.category = category
        self.presentation = presentation
        self.highlightedPlaceID = highlightedPlaceID
        self.selectedPlaceID = selectedPlaceID
        self.isRefreshing = isRefreshing
        self.isLocationPickerPresented = isLocationPickerPresented
    }
}

public enum ExploreIntent: Equatable, Sendable {
    case onAppear
    case refresh
    case retry
    case selectLocation(Location)
    case queryChanged(String)
    case selectCategory(PlaceCategory?)
    case clearFilters
    case presentation(ExplorePresentation)
    case selectPlace(String?)
    case highlightPlace(String?)
    case showLocationPicker
    case dismissLocationPicker
}

public enum ExploreAction: Equatable, Sendable {
    case loadStarted
    case refreshStarted
    case loaded([LocalPlace])
    case failed(AppError)
    case empty
    case locationChanged(Location)
    case query(String, PlaceCategory?)
    case presentation(ExplorePresentation)
    case place(String?)
    case highlight(String?)
    case presentLocationPicker(Bool)
}

public enum ExploreReducer {
    public static func reduce(_ state: ExploreState, _ action: ExploreAction) -> ExploreState {
        var state = state
        switch action {
        case .loadStarted:
            state.places = .loading
            state.visiblePlaces = []
            state.isRefreshing = false
        case .refreshStarted:
            state.isRefreshing = true
        case let .loaded(places):
            state.places = places.isEmpty ? .empty : .loaded(places)
            state.visiblePlaces = filtered(places, state: state)
            state.isRefreshing = false
            state.isLocationPickerPresented = false
        case let .failed(error):
            state.places = .failed(error)
            state.visiblePlaces = []
            state.isRefreshing = false
        case .empty:
            state.places = .empty
            state.visiblePlaces = []
            state.isRefreshing = false
        case let .locationChanged(location):
            state.selectedLocation = location
            state.selectedPlaceID = nil
            state.highlightedPlaceID = nil
            state.isLocationPickerPresented = false
        case let .query(text, category):
            state.query = text
            state.category = category
            state.visiblePlaces = filtered(state.places.value ?? [], state: state)
        case let .presentation(presentation):
            state.presentation = presentation
        case let .place(id):
            state.selectedPlaceID = id
        case let .highlight(id):
            state.highlightedPlaceID = id
        case let .presentLocationPicker(isPresented):
            state.isLocationPickerPresented = isPresented
        }
        return state
    }

    private static func filtered(_ places: [LocalPlace], state: ExploreState) -> [LocalPlace] {
        SearchLocalPlacesUseCase.filter(
            places,
            near: state.selectedLocation,
            query: SearchLocalPlacesUseCase.Query(text: state.query, category: state.category)
        )
    }
}
