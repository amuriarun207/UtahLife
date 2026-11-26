import Combine
import CoreKit
import DomainKit
import FeatureUI
import Foundation

@MainActor
public final class HomeStore: ObservableObject {
    @Published public private(set) var state: HomeState
    private let dashboard: LoadHomeDashboardUseCase
    private let selectLocation: SelectLocationUseCase
    private let loadsOnAppear: Bool
    private var generation = 0

    public init(
        location: Location,
        locations: [Location],
        dashboard: LoadHomeDashboardUseCase,
        selectLocation: SelectLocationUseCase,
        loadsOnAppear: Bool = true,
        seeded: HomeState? = nil
    ) {
        self.dashboard = dashboard
        self.selectLocation = selectLocation
        self.loadsOnAppear = loadsOnAppear
        self.state = seeded ?? HomeState(selectedLocation: location, locations: locations)
    }

    public static func preview(_ state: HomeState) -> HomeStore {
        HomeStore(
            location: state.selectedLocation,
            locations: state.locations,
            dashboard: PreviewSupport.homeDashboard(),
            selectLocation: PreviewSupport.selectLocation(),
            loadsOnAppear: false,
            seeded: state
        )
    }

    public func send(_ intent: HomeIntent) async {
        switch intent {
        case .onAppear:
            guard loadsOnAppear, state.weather == .idle else { return }
            await load(refresh: false)
        case .refresh:
            await load(refresh: true)
        case .retry:
            await load(refresh: false)
        case let .selectLocation(location):
            await applyLocation(location)
        case .weatherTapped:
            state = HomeReducer.reduce(state, .requestNavigation(.environment(.weather)))
        case .airQualityTapped:
            state = HomeReducer.reduce(state, .requestNavigation(.environment(.airQuality)))
        case .trafficTapped, .seeAllTravel:
            state = HomeReducer.reduce(state, .requestNavigation(.travel))
        case let .alertTapped(id):
            state = HomeReducer.reduce(state, .requestNavigation(.alert(id: id)))
        case .seeAllAlerts:
            state = HomeReducer.reduce(state, .requestNavigation(.alerts))
        case .seeAllExplore:
            state = HomeReducer.reduce(state, .requestNavigation(.explore))
        case .showLocationPicker:
            state = HomeReducer.reduce(state, .presentLocationPicker(true))
        case .dismissLocationPicker:
            state = HomeReducer.reduce(state, .presentLocationPicker(false))
        case .navigationConsumed:
            state = HomeReducer.reduce(state, .clearNavigation)
        }
    }

    private func applyLocation(_ location: Location) async {
        do {
            let selected = try await selectLocation.execute(location: location, available: state.locations)
            let changed = selected.id != state.selectedLocation.id
            state = HomeReducer.reduce(state, .locationChanged(selected))
            guard changed else { return }
            await load(refresh: state.weather.value != nil)
        } catch {
            state = HomeReducer.reduce(state, .dashboardFailed(AppError(error)))
        }
    }

    private func load(refresh: Bool) async {
        generation += 1
        let generation = generation
        let location = state.selectedLocation
        state = HomeReducer.reduce(state, refresh ? .refreshStarted : .loadStarted)
        do {
            let data = try await dashboard.execute(location: location)
            guard generation == self.generation else { return }
            state = HomeReducer.reduce(state, .dashboardLoaded(data))
        } catch is CancellationError {
            return
        } catch {
            guard generation == self.generation else { return }
            let appError = AppError(error)
            if appError.isEmpty {
                state = HomeReducer.reduce(state, .dashboardEmpty)
            } else {
                state = HomeReducer.reduce(state, .dashboardFailed(appError))
            }
        }
    }
}
