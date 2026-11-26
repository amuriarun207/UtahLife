public enum A11yID {
    public static let tabHome = "tab.home"
    public static let tabExplore = "tab.explore"
    public static let tabTravel = "tab.travel"
    public static let tabEnvironment = "tab.environment"
    public static let tabAlerts = "tab.alerts"

    public static let screenHome = "screen.home"
    public static let screenExplore = "screen.explore"
    public static let screenTravel = "screen.travel"
    public static let screenEnvironment = "screen.environment"
    public static let screenAlerts = "screen.alerts"

    public static let homeLocationButton = "home.locationButton"
    public static let homeWeatherCard = "home.weatherCard"
    public static let homeAirQualityCard = "home.airQualityCard"
    public static let homeTrafficCard = "home.trafficCard"
    public static let homeAlertPreview = "home.alertPreview"
    public static let homeSeeAllAlerts = "home.seeAllAlerts"
    public static let homeQuickTravel = "home.quick.travel"
    public static let homeQuickEnvironment = "home.quick.environment"
    public static let homeQuickExplore = "home.quick.explore"

    public static let stateRetry = "state.retry"
    public static let stateEmpty = "state.empty"
    public static let stateLoading = "state.loading"

    public static let exploreSearch = "explore.search"
    public static let exploreClear = "explore.clear"
    public static let exploreMap = "explore.map"
    public static let exploreList = "explore.list"

    public static let travelMap = "travel.map"
    public static let travelList = "travel.list"

    public static let environmentAQIDisclosure = "environment.aqiDisclosure"
    public static let environmentAQIExplanation = "environment.aqiExplanation"

    public static let alertsMarkAll = "alerts.markAll"
    public static let alertsMarkRead = "alerts.markRead"
    public static let alertsPreferences = "alerts.preferences"
    public static let alertsPreferenceMaster = "alerts.preferences.master"

    public static func locationRow(_ id: String) -> String { "location.row.\(id)" }
    public static func exploreChip(_ id: String) -> String { "explore.chip.\(id)" }
    public static func placeRow(_ id: String) -> String { "explore.place.\(id)" }
    public static func travelSeverity(_ id: String) -> String { "travel.severity.\(id)" }
    public static func travelType(_ id: String) -> String { "travel.type.\(id)" }
    public static func incidentRow(_ id: String) -> String { "travel.incident.\(id)" }
    public static func forecastRow(_ id: String) -> String { "environment.forecast.\(id)" }
    public static func alertRow(_ id: String) -> String { "alerts.row.\(id)" }
    public static func alertCategory(_ id: String) -> String { "alerts.category.\(id)" }
    public static func cameraCard(_ id: String) -> String { "travel.camera.\(id)" }
    public static func commuteRow(_ id: String) -> String { "travel.commute.\(id)" }
}
