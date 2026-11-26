import Combine
import CoreKit
import DomainKit
import FeatureUI

@MainActor
public final class ExploreStore: ObservableObject {
    @Published public private(set) var state: ExploreState
    private let search: SearchLocalPlacesUseCase
    private let selectLocation: SelectLocationUseCase
    private let loadsOnAppear: Bool
    private var generation = 0

    public init(
        location: Location,
        locations: [Location],
        search: SearchLocalPlacesUseCase,
        selectLocation: SelectLocationUseCase,
        loadsOnAppear: Bool = true,
        seeded: ExploreState? = nil
    ) {
        self.search = search
        self.selectLocation = selectLocation
        self.loadsOnAppear = loadsOnAppear
        self.state = seeded ?? ExploreState(selectedLocation: location, locations: locations)
    }

    public static func preview(_ state: ExploreState) -> ExploreStore {
        ExploreStore(
            location: state.selectedLocation,
            locations: state.locations,
            search: PreviewSupport.places(),
            selectLocation: PreviewSupport.selectLocation(),
            loadsOnAppear: false,
            seeded: state
        )
    }

    public func send(_ intent: ExploreIntent) async {
        switch intent {
        case .onAppear:
            guard loadsOnAppear, state.places == .idle else { return }
            await load(refresh: false)
        case .refresh:
            await load(refresh: true)
        case .retry:
            await load(refresh: false)
        case let .selectLocation(location):
            await applyLocation(location)
        case let .queryChanged(text):
            state = ExploreReducer.reduce(state, .query(text, state.category))
        case let .selectCategory(category):
            let next = state.category == category ? nil : category
            state = ExploreReducer.reduce(state, .query(state.query, next))
        case .clearFilters:
            state = ExploreReducer.reduce(state, .query("", nil))
        case let .presentation(presentation):
            state = ExploreReducer.reduce(state, .presentation(presentation))
        case let .selectPlace(id):
            state = ExploreReducer.reduce(state, .place(id))
        case let .highlightPlace(id):
            state = ExploreReducer.reduce(state, .highlight(id))
        case .showLocationPicker:
            state = ExploreReducer.reduce(state, .presentLocationPicker(true))
        case .dismissLocationPicker:
            state = ExploreReducer.reduce(state, .presentLocationPicker(false))
        }
    }

    private func applyLocation(_ location: Location) async {
        do {
            let selected = try await selectLocation.execute(location: location, available: state.locations)
            let changed = selected.id != state.selectedLocation.id
            state = ExploreReducer.reduce(state, .locationChanged(selected))
            guard changed else { return }
            await load(refresh: state.places.value != nil)
        } catch {
            state = ExploreReducer.reduce(state, .failed(AppError(error)))
        }
    }

    private func load(refresh: Bool) async {
        generation += 1
        let generation = generation
        let location = state.selectedLocation
        let query = SearchLocalPlacesUseCase.Query(text: state.query, category: state.category)
        state = ExploreReducer.reduce(state, refresh ? .refreshStarted : .loadStarted)
        do {
            let places = try await search.load(location: location, query: SearchLocalPlacesUseCase.Query(text: "", category: nil))
            guard generation == self.generation else { return }
            var loaded = ExploreReducer.reduce(state, .loaded(places))
            loaded = ExploreReducer.reduce(loaded, .query(query.text, query.category))
            state = loaded
        } catch is CancellationError {
            return
        } catch {
            guard generation == self.generation else { return }
            let appError = AppError(error)
            state = ExploreReducer.reduce(state, appError.isEmpty ? .empty : .failed(appError))
        }
    }
}
