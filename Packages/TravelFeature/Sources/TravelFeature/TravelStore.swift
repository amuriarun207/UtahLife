import Combine
import CoreKit
import DomainKit
import FeatureUI

@MainActor
public final class TravelStore: ObservableObject {
    @Published public private(set) var state: TravelState
    private let loader: LoadTravelOverviewUseCase
    private let selectLocation: SelectLocationUseCase
    private let loadsOnAppear: Bool
    private var generation = 0

    public init(
        location: Location,
        locations: [Location],
        loader: LoadTravelOverviewUseCase,
        selectLocation: SelectLocationUseCase,
        loadsOnAppear: Bool = true,
        seeded: TravelState? = nil
    ) {
        self.loader = loader
        self.selectLocation = selectLocation
        self.loadsOnAppear = loadsOnAppear
        self.state = seeded ?? TravelState(selectedLocation: location, locations: locations)
    }

    public static func preview(_ state: TravelState) -> TravelStore {
        TravelStore(
            location: state.selectedLocation,
            locations: state.locations,
            loader: PreviewSupport.travel(),
            selectLocation: PreviewSupport.selectLocation(),
            loadsOnAppear: false,
            seeded: state
        )
    }

    public func send(_ intent: TravelIntent) async {
        switch intent {
        case .onAppear:
            guard loadsOnAppear, state.overview == .idle else { return }
            await load(refresh: false)
        case .refresh:
            await load(refresh: true)
        case .retry:
            await load(refresh: false)
        case let .selectLocation(location):
            await applyLocation(location)
        case let .toggleSeverity(severity):
            var filters = state.severityFilter
            if filters.contains(severity) { filters.remove(severity) } else { filters.insert(severity) }
            state = TravelReducer.reduce(state, .filters(filters, state.typeFilter))
        case let .toggleType(type):
            var filters = state.typeFilter
            if filters.contains(type) { filters.remove(type) } else { filters.insert(type) }
            state = TravelReducer.reduce(state, .filters(state.severityFilter, filters))
        case .clearFilters:
            state = TravelReducer.reduce(state, .filters([], []))
        case let .presentation(presentation):
            state = TravelReducer.reduce(state, .presentation(presentation))
        case let .selectIncident(id):
            state = TravelReducer.reduce(state, .incident(id))
        case let .selectCommute(id):
            state = TravelReducer.reduce(state, .commute(id))
        case let .selectCamera(id):
            state = TravelReducer.reduce(state, .camera(id))
        }
    }

    private func applyLocation(_ location: Location) async {
        do {
            let selected = try await selectLocation.execute(location: location, available: state.locations)
            let changed = selected.id != state.selectedLocation.id
            state = TravelReducer.reduce(state, .locationChanged(selected))
            guard changed else { return }
            await load(refresh: state.overview.value != nil)
        } catch {
            state = TravelReducer.reduce(state, .failed(AppError(error)))
        }
    }

    private func load(refresh: Bool) async {
        generation += 1
        let generation = generation
        let location = state.selectedLocation
        state = TravelReducer.reduce(state, refresh ? .refreshStarted : .loadStarted)
        do {
            let overview = try await loader.execute(location: location)
            guard generation == self.generation else { return }
            state = TravelReducer.reduce(state, .loaded(overview))
        } catch is CancellationError {
            return
        } catch {
            guard generation == self.generation else { return }
            let appError = AppError(error)
            state = TravelReducer.reduce(state, appError.isEmpty ? .empty : .failed(appError))
        }
    }
}
