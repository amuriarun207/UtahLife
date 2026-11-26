import CoreKit
import DomainKit
import Foundation

public enum PreviewSupport {
    public static func homeDashboard() -> LoadHomeDashboardUseCase {
        LoadHomeDashboardUseCase(
            weatherRepository: PreviewWeatherRepository(),
            airQualityRepository: PreviewAirRepository(),
            trafficRepository: PreviewTrafficRepository(),
            alertsRepository: PreviewAlertsRepository(),
            dates: FixedDateProvider(date: PreviewCatalog.observedAt)
        )
    }

    public static func environment() -> LoadEnvironmentUseCase {
        LoadEnvironmentUseCase(
            weatherRepository: PreviewWeatherRepository(),
            airQualityRepository: PreviewAirRepository()
        )
    }

    public static func travel() -> LoadTravelOverviewUseCase {
        LoadTravelOverviewUseCase(repository: PreviewTrafficRepository())
    }

    public static func places() -> SearchLocalPlacesUseCase {
        SearchLocalPlacesUseCase(repository: PreviewPlacesRepository())
    }

    public static func markRead() -> MarkAlertAsReadUseCase {
        MarkAlertAsReadUseCase(repository: PreviewAlertsRepository())
    }

    public static func markAll() -> MarkAllAlertsAsReadUseCase {
        MarkAllAlertsAsReadUseCase(repository: PreviewAlertsRepository())
    }

    public static func selectLocation() -> SelectLocationUseCase {
        SelectLocationUseCase(preferences: MemoryLocationPreferences())
    }
}

struct PreviewWeatherRepository: WeatherRepositoryProtocol {
    func currentWeather(for location: Location) async throws -> Weather { PreviewCatalog.weather }
    func hourlyForecast(for location: Location) async throws -> [HourlyForecast] { PreviewCatalog.hourly }
    func dailyForecast(for location: Location) async throws -> [ForecastDay] { PreviewCatalog.daily }
}

struct PreviewAirRepository: AirQualityRepositoryProtocol {
    func airQuality(for location: Location) async throws -> AirQuality { PreviewCatalog.airQuality }
}

struct PreviewTrafficRepository: TrafficRepositoryProtocol {
    func incidents(for location: Location) async throws -> [TrafficIncident] {
        [PreviewCatalog.incident, PreviewCatalog.moderateIncident, PreviewCatalog.lowIncident]
    }
    func roadConditions(for location: Location) async throws -> [RoadCondition] { [PreviewCatalog.road] }
    func savedCommutes(for location: Location) async throws -> [SavedCommute] { [PreviewCatalog.commute] }
    func cameras(for location: Location) async throws -> [MockCamera] { [PreviewCatalog.camera] }
}

actor PreviewAlertsRepository: AlertsRepositoryProtocol {
    func alerts(for location: Location) async throws -> [LocalAlert] {
        [PreviewCatalog.unreadAlert, PreviewCatalog.readAlert]
    }
    func markAsRead(id: String) async throws {}
    func markAllAsRead() async throws {}
}

struct PreviewPlacesRepository: LocalPlacesRepositoryProtocol {
    func places(near location: Location) async throws -> [LocalPlace] {
        [PreviewCatalog.park, PreviewCatalog.library, PreviewCatalog.hospital]
    }
}
