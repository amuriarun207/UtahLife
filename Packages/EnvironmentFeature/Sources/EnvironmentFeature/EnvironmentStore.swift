import Combine
import CoreKit
import DomainKit
import FeatureUI

@MainActor
public final class EnvironmentStore: ObservableObject {
    @Published public private(set) var state: EnvironmentState
    private let loader: LoadEnvironmentUseCase
    private let selectLocation: SelectLocationUseCase
    private let loadsOnAppear: Bool
    private var generation = 0

    public init(
        location: Location,
        locations: [Location],
        loader: LoadEnvironmentUseCase,
        selectLocation: SelectLocationUseCase,
        loadsOnAppear: Bool = true,
        seeded: EnvironmentState? = nil
    ) {
        self.loader = loader
        self.selectLocation = selectLocation
        self.loadsOnAppear = loadsOnAppear
        self.state = seeded ?? EnvironmentState(selectedLocation: location, locations: locations)
    }

    public static func preview(_ state: EnvironmentState) -> EnvironmentStore {
        EnvironmentStore(
            location: state.selectedLocation,
            locations: state.locations,
            loader: PreviewSupport.environment(),
            selectLocation: PreviewSupport.selectLocation(),
            loadsOnAppear: false,
            seeded: state
        )
    }

    public func send(_ intent: EnvironmentIntent) async {
        switch intent {
        case .onAppear:
            guard loadsOnAppear, state.snapshot == .idle else { return }
            await load(refresh: false)
        case .refresh:
            await load(refresh: true)
        case .retry:
            await load(refresh: false)
        case let .selectLocation(location):
            await applyLocation(location)
        case let .selectSection(section), let .focus(section):
            state = EnvironmentReducer.reduce(state, .section(section))
        case let .selectDay(id):
            state = EnvironmentReducer.reduce(state, .day(id))
        case .toggleAQIExplanation:
            state = EnvironmentReducer.reduce(state, .aqiExpanded(state.isAQIExpanded == false))
        case .showLocationPicker:
            state = EnvironmentReducer.reduce(state, .presentLocationPicker(true))
        case .dismissLocationPicker:
            state = EnvironmentReducer.reduce(state, .presentLocationPicker(false))
        }
    }

    private func applyLocation(_ location: Location) async {
        do {
            let selected = try await selectLocation.execute(location: location, available: state.locations)
            let changed = selected.id != state.selectedLocation.id
            state = EnvironmentReducer.reduce(state, .locationChanged(selected))
            guard changed else { return }
            await load(refresh: state.snapshot.value != nil)
        } catch {
            state = EnvironmentReducer.reduce(state, .failed(AppError(error)))
        }
    }

    private func load(refresh: Bool) async {
        generation += 1
        let generation = generation
        let location = state.selectedLocation
        state = EnvironmentReducer.reduce(state, refresh ? .refreshStarted : .loadStarted)
        do {
            let snapshot = try await loader.execute(location: location)
            guard generation == self.generation else { return }
            state = EnvironmentReducer.reduce(state, .loaded(snapshot))
        } catch is CancellationError {
            return
        } catch {
            guard generation == self.generation else { return }
            let appError = AppError(error)
            state = EnvironmentReducer.reduce(state, appError.isEmpty ? .empty : .failed(appError))
        }
    }
}
