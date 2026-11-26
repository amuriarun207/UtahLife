import CoreKit
import DomainKit
import Foundation

public enum HomeNavigation: Equatable, Sendable {
    case environment(EnvironmentFocus)
    case travel
    case explore
    case alerts
    case alert(id: String)
}

public struct HomeState: Equatable {
    public var selectedLocation: Location
    public var locations: [Location]
    public var greeting: String
    public var weather: AsyncValue<Weather>
    public var hourly: AsyncValue<[HourlyForecast]>
    public var airQuality: AsyncValue<AirQuality>
    public var traffic: AsyncValue<TrafficSummary>
    public var alerts: AsyncValue<[LocalAlert]>
    public var isRefreshing: Bool
    public var isLocationPickerPresented: Bool
    public var navigation: HomeNavigation?

    public init(
        selectedLocation: Location,
        locations: [Location],
        greeting: String = "",
        weather: AsyncValue<Weather> = .idle,
        hourly: AsyncValue<[HourlyForecast]> = .idle,
        airQuality: AsyncValue<AirQuality> = .idle,
        traffic: AsyncValue<TrafficSummary> = .idle,
        alerts: AsyncValue<[LocalAlert]> = .idle,
        isRefreshing: Bool = false,
        isLocationPickerPresented: Bool = false,
        navigation: HomeNavigation? = nil
    ) {
        self.selectedLocation = selectedLocation
        self.locations = locations
        self.greeting = greeting
        self.weather = weather
        self.hourly = hourly
        self.airQuality = airQuality
        self.traffic = traffic
        self.alerts = alerts
        self.isRefreshing = isRefreshing
        self.isLocationPickerPresented = isLocationPickerPresented
        self.navigation = navigation
    }
}

public enum HomeIntent: Equatable, Sendable {
    case onAppear
    case refresh
    case retry
    case selectLocation(Location)
    case weatherTapped
    case airQualityTapped
    case trafficTapped
    case alertTapped(String)
    case seeAllAlerts
    case seeAllTravel
    case seeAllExplore
    case showLocationPicker
    case dismissLocationPicker
    case navigationConsumed
}

public enum HomeAction: Equatable, Sendable {
    case loadStarted
    case refreshStarted
    case dashboardLoaded(DashboardData)
    case dashboardFailed(AppError)
    case dashboardEmpty
    case locationChanged(Location)
    case presentLocationPicker(Bool)
    case requestNavigation(HomeNavigation)
    case clearNavigation
}

public enum HomeReducer {
    public static func reduce(_ state: HomeState, _ action: HomeAction) -> HomeState {
        var state = state
        switch action {
        case .loadStarted:
            state.weather = .loading
            state.hourly = .loading
            state.airQuality = .loading
            state.traffic = .loading
            state.alerts = .loading
            state.isRefreshing = false
        case .refreshStarted:
            state.isRefreshing = true
        case let .dashboardLoaded(data):
            state.selectedLocation = data.location
            state.greeting = data.greeting
            state.weather = .loaded(data.weather)
            state.hourly = data.hourly.isEmpty ? .empty : .loaded(data.hourly)
            state.airQuality = .loaded(data.airQuality)
            state.traffic = .loaded(data.traffic)
            state.alerts = data.alerts.isEmpty ? .empty : .loaded(Array(data.alerts.prefix(3)))
            state.isRefreshing = false
            state.isLocationPickerPresented = false
        case let .dashboardFailed(error):
            state.weather = .failed(error)
            state.hourly = .failed(error)
            state.airQuality = .failed(error)
            state.traffic = .failed(error)
            state.alerts = .failed(error)
            state.isRefreshing = false
        case .dashboardEmpty:
            state.weather = .empty
            state.hourly = .empty
            state.airQuality = .empty
            state.traffic = .empty
            state.alerts = .empty
            state.isRefreshing = false
        case let .locationChanged(location):
            state.selectedLocation = location
            state.isLocationPickerPresented = false
        case let .presentLocationPicker(isPresented):
            state.isLocationPickerPresented = isPresented
        case let .requestNavigation(navigation):
            state.navigation = navigation
        case .clearNavigation:
            state.navigation = nil
        }
        return state
    }
}
