import Combine
import CoreKit
import DomainKit
import FeatureUI

@MainActor
public final class AlertsStore: ObservableObject {
    @Published public private(set) var state: AlertsState
    private let loader: LoadAlertsUseCase
    private let markRead: MarkAlertAsReadUseCase
    private let markAll: MarkAllAlertsAsReadUseCase
    private let preferencesUseCase: NotificationPreferencesUseCase
    private let selectLocation: SelectLocationUseCase
    private let loadsOnAppear: Bool
    private var generation = 0

    public init(
        location: Location,
        locations: [Location],
        loader: LoadAlertsUseCase,
        markRead: MarkAlertAsReadUseCase,
        markAll: MarkAllAlertsAsReadUseCase,
        preferences: NotificationPreferencesUseCase,
        selectLocation: SelectLocationUseCase,
        loadsOnAppear: Bool = true,
        seeded: AlertsState? = nil
    ) {
        self.loader = loader
        self.markRead = markRead
        self.markAll = markAll
        self.preferencesUseCase = preferences
        self.selectLocation = selectLocation
        self.loadsOnAppear = loadsOnAppear
        self.state = seeded ?? AlertsState(selectedLocation: location, locations: locations)
    }

    public static func preview(_ state: AlertsState) -> AlertsStore {
        let repository = SeedAlertsRepository()
        return AlertsStore(
            location: state.selectedLocation,
            locations: state.locations,
            loader: LoadAlertsUseCase(repository: repository),
            markRead: MarkAlertAsReadUseCase(repository: repository),
            markAll: MarkAllAlertsAsReadUseCase(repository: repository),
            preferences: NotificationPreferencesUseCase(repository: MemoryNotificationPreferences()),
            selectLocation: PreviewSupport.selectLocation(),
            loadsOnAppear: false,
            seeded: state
        )
    }

    public func send(_ intent: AlertsIntent) async {
        switch intent {
        case .onAppear:
            guard loadsOnAppear, state.alerts == .idle else { return }
            await loadPreferences()
            await load(refresh: false)
        case .refresh:
            await load(refresh: true)
        case .retry:
            await load(refresh: false)
        case let .selectLocation(location):
            await applyLocation(location)
        case let .toggleCategory(category):
            var categories = state.categories
            if categories.contains(category) { categories.remove(category) } else { categories.insert(category) }
            state = AlertsReducer.reduce(state, .filters(categories, state.severities))
        case let .toggleSeverity(severity):
            var severities = state.severities
            if severities.contains(severity) { severities.remove(severity) } else { severities.insert(severity) }
            state = AlertsReducer.reduce(state, .filters(state.categories, severities))
        case .clearFilters:
            state = AlertsReducer.reduce(state, .filters([], []))
        case let .selectAlert(id):
            state = AlertsReducer.reduce(state, .selected(id))
        case let .openAlert(id):
            state = AlertsReducer.reduce(state, .pending(id))
        case let .markRead(id):
            await update {
                try await markRead.execute(id: id, location: state.selectedLocation)
            }
        case .markAllRead:
            await update {
                try await markAll.execute(location: state.selectedLocation)
            }
        case .showPreferences:
            state = AlertsReducer.reduce(state, .preferences(state.preferences, presented: true))
        case .dismissPreferences:
            state = AlertsReducer.reduce(state, .preferences(state.preferences, presented: false))
        case let .setMasterEnabled(isEnabled):
            var preferences = state.preferences
            preferences.masterEnabled = isEnabled
            await preferencesUseCase.update(preferences)
            state = AlertsReducer.reduce(state, .preferences(preferences, presented: state.isPreferencesPresented))
        case let .setCategoryEnabled(category, isEnabled):
            var preferences = state.preferences
            preferences.categories[category] = isEnabled
            await preferencesUseCase.update(preferences)
            state = AlertsReducer.reduce(state, .preferences(preferences, presented: state.isPreferencesPresented))
        }
    }

    private func applyLocation(_ location: Location) async {
        do {
            let selected = try await selectLocation.execute(location: location, available: state.locations)
            let changed = selected.id != state.selectedLocation.id
            state = AlertsReducer.reduce(state, .locationChanged(selected))
            guard changed else { return }
            await load(refresh: state.alerts.value != nil)
        } catch {
            state = AlertsReducer.reduce(state, .failed(AppError(error)))
        }
    }

    private func loadPreferences() async {
        let preferences = await preferencesUseCase.load()
        state = AlertsReducer.reduce(state, .preferences(preferences, presented: state.isPreferencesPresented))
    }

    private func load(refresh: Bool) async {
        generation += 1
        let generation = generation
        let location = state.selectedLocation
        state = AlertsReducer.reduce(state, refresh ? .refreshStarted : .loadStarted)
        do {
            let alerts = try await loader.execute(location: location)
            guard generation == self.generation else { return }
            state = AlertsReducer.reduce(state, .loaded(alerts))
        } catch is CancellationError {
            return
        } catch {
            guard generation == self.generation else { return }
            let appError = AppError(error)
            state = AlertsReducer.reduce(state, appError.isEmpty ? .empty : .failed(appError))
        }
    }

    private func update(_ operation: () async throws -> [LocalAlert]) async {
        do {
            let alerts = try await operation()
            state = AlertsReducer.reduce(state, .loaded(alerts))
        } catch {
            state = AlertsReducer.reduce(state, .failed(AppError(error)))
        }
    }
}

private actor SeedAlertsRepository: AlertsRepositoryProtocol {
    private var alerts = [PreviewCatalog.unreadAlert, PreviewCatalog.readAlert]

    func alerts(for location: Location) async throws -> [LocalAlert] {
        alerts.filter { $0.locationId == location.id }
    }

    func markAsRead(id: String) async throws {
        alerts = alerts.map { alert in
            guard alert.id == id else { return alert }
            var copy = alert
            copy.isRead = true
            return copy
        }
    }

    func markAllAsRead() async throws {
        alerts = alerts.map { alert in
            var copy = alert
            copy.isRead = true
            return copy
        }
    }
}
