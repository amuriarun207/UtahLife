import AlertsFeature
import Combine
import CoreKit
import DataKit
import DomainKit
import EnvironmentFeature
import ExploreFeature
import Foundation
import HomeFeature
import TravelFeature

@MainActor
final class AppDependencies: ObservableObject {
    let router: AppRouter
    let locations: LocationSelectionModel
    let locationProvider: MockLocationProvider
    let home: HomeStore
    let explore: ExploreStore
    let travel: TravelStore
    let environment: EnvironmentStore
    let alerts: AlertsStore

    init(
        router: AppRouter,
        locations: LocationSelectionModel,
        locationProvider: MockLocationProvider,
        home: HomeStore,
        explore: ExploreStore,
        travel: TravelStore,
        environment: EnvironmentStore,
        alerts: AlertsStore
    ) {
        self.router = router
        self.locations = locations
        self.locationProvider = locationProvider
        self.home = home
        self.explore = explore
        self.travel = travel
        self.environment = environment
        self.alerts = alerts
    }

    static func make(arguments: [String] = ProcessInfo.processInfo.arguments) async throws -> AppDependencies {
        let scenario = FixtureScenario.from(arguments: arguments)
        let delay = ImmediateDelayPolicy()
        let locationRepository = try MockLocationRepository(scenario: scenario, delay: delay)
        let weather = try MockWeatherRepository(scenario: scenario, delay: delay)
        let air = try MockAirQualityRepository(scenario: scenario, delay: delay)
        let traffic = try MockTrafficRepository(scenario: scenario, delay: delay)
        let places = try MockLocalPlacesRepository(scenario: scenario, delay: delay)
        let alerts = try MockAlertsRepository(scenario: scenario, delay: delay)
        let locationPreferences = UserDefaultsLocationPreferences(defaults: .standard)
        let notificationPreferences = UserDefaultsNotificationPreferences(defaults: .standard)
        if arguments.contains("-UtahLifeResetPreferences") {
            UserDefaults.standard.removeObject(forKey: "utahlife.selectedLocationID")
            UserDefaults.standard.removeObject(forKey: "utahlife.notificationPreferences")
        }
        let available = try await locationRepository.locations()
        let selectLocation = SelectLocationUseCase(preferences: locationPreferences)
        let locationProvider = MockLocationProvider(locationsRepository: locationRepository, preferences: locationPreferences)
        let selected = try await selectLocation.restore(available: available)
        let dates = SystemDateProvider()

        let home = HomeStore(
            location: selected,
            locations: available,
            dashboard: LoadHomeDashboardUseCase(
                weatherRepository: weather,
                airQualityRepository: air,
                trafficRepository: traffic,
                alertsRepository: alerts,
                dates: dates
            ),
            selectLocation: selectLocation
        )
        let environment = EnvironmentStore(
            location: selected,
            locations: available,
            loader: LoadEnvironmentUseCase(weatherRepository: weather, airQualityRepository: air),
            selectLocation: selectLocation
        )
        let travel = TravelStore(
            location: selected,
            locations: available,
            loader: LoadTravelOverviewUseCase(repository: traffic),
            selectLocation: selectLocation
        )
        let explore = ExploreStore(
            location: selected,
            locations: available,
            search: SearchLocalPlacesUseCase(repository: places),
            selectLocation: selectLocation
        )
        let alertsStore = AlertsStore(
            location: selected,
            locations: available,
            loader: LoadAlertsUseCase(repository: alerts),
            markRead: MarkAlertAsReadUseCase(repository: alerts),
            markAll: MarkAllAlertsAsReadUseCase(repository: alerts),
            preferences: NotificationPreferencesUseCase(repository: notificationPreferences),
            selectLocation: selectLocation
        )
        return AppDependencies(
            router: AppRouter(),
            locations: LocationSelectionModel(locations: available, selected: selected, selectLocation: selectLocation),
            locationProvider: locationProvider,
            home: home,
            explore: explore,
            travel: travel,
            environment: environment,
            alerts: alertsStore
        )
    }

    func select(_ location: Location) async {
        await locations.select(location)
        await home.send(.selectLocation(location))
        await explore.send(.selectLocation(location))
        await travel.send(.selectLocation(location))
        await environment.send(.selectLocation(location))
        await alerts.send(.selectLocation(location))
    }
}

@MainActor
final class LocationSelectionModel: ObservableObject {
    @Published private(set) var locations: [Location]
    @Published private(set) var selected: Location
    private let selectLocation: SelectLocationUseCase

    init(locations: [Location], selected: Location, selectLocation: SelectLocationUseCase) {
        self.locations = locations
        self.selected = selected
        self.selectLocation = selectLocation
    }

    func select(_ location: Location) async {
        guard let updated = try? await selectLocation.execute(location: location, available: locations) else {
            return
        }
        selected = updated
    }
}

enum AppTab: Hashable {
    case home
    case explore
    case travel
    case environment
    case alerts
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var tab: AppTab = .home

    func open(_ navigation: HomeNavigation, environment: EnvironmentStore, alerts: AlertsStore) async {
        switch navigation {
        case let .environment(focus):
            await environment.send(.focus(focus))
            tab = .environment
        case .travel:
            tab = .travel
        case .explore:
            tab = .explore
        case .alerts:
            tab = .alerts
        case let .alert(id):
            await alerts.send(.openAlert(id))
            tab = .alerts
        }
    }
}
