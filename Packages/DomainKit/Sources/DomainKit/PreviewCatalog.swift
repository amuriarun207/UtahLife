import Foundation

public enum PreviewCatalog {
    public static let saltLakeCity = Location(
        id: "slc",
        name: "Salt Lake City",
        city: "Salt Lake City",
        state: "UT",
        postalCode: "84101",
        latitude: 40.7608,
        longitude: -111.8910,
        timezoneIdentifier: "America/Denver",
        isDefault: true
    )

    public static let westJordan = Location(
        id: "west-jordan",
        name: "West Jordan",
        city: "West Jordan",
        state: "UT",
        postalCode: "84084",
        latitude: 40.6097,
        longitude: -111.9391,
        timezoneIdentifier: "America/Denver",
        isDefault: false
    )

    public static let observedAt = Date(timeIntervalSince1970: 1_768_225_800)

    public static let weather = Weather(
        locationId: saltLakeCity.id,
        observedAt: observedAt,
        temperature: MeasurementValue(value: 31, unitSymbol: "°F"),
        feelsLike: MeasurementValue(value: 28, unitSymbol: "°F"),
        high: MeasurementValue(value: 36, unitSymbol: "°F"),
        low: MeasurementValue(value: 22, unitSymbol: "°F"),
        condition: .partlyCloudy,
        humidity: MeasurementValue(value: 48, unitSymbol: "%"),
        windSpeed: MeasurementValue(value: 8, unitSymbol: " mph"),
        precipitationProbability: MeasurementValue(value: 20, unitSymbol: "%"),
        isMockData: true
    )

    public static let hourly: [HourlyForecast] = makeHourly()
    public static let daily: [ForecastDay] = makeDaily()

    private static func makeHourly() -> [HourlyForecast] {
        var forecasts: [HourlyForecast] = []
        for index in 0..<4 {
            let temperature = MeasurementValue(value: Double(30 + index), unitSymbol: "°F")
            let precipitation = MeasurementValue(value: Double(10 + index * 5), unitSymbol: "%")
            forecasts.append(
                HourlyForecast(
                    id: "slc-hour-\(index)",
                    locationId: saltLakeCity.id,
                    dateTime: observedAt.addingTimeInterval(Double(index) * 3600),
                    temperature: temperature,
                    condition: index == 2 ? .snow : .partlyCloudy,
                    precipitationProbability: precipitation,
                    isMockData: true
                )
            )
        }
        return forecasts
    }

    private static func makeDaily() -> [ForecastDay] {
        var days: [ForecastDay] = []
        for index in 0..<7 {
            let high = MeasurementValue(value: Double(34 + index), unitSymbol: "°F")
            let low = MeasurementValue(value: Double(20 + index), unitSymbol: "°F")
            let precipitation = MeasurementValue(value: Double(15 + index * 5), unitSymbol: "%")
            days.append(
                ForecastDay(
                    id: "slc-day-\(index)",
                    locationId: saltLakeCity.id,
                    date: observedAt.addingTimeInterval(Double(index) * 86_400),
                    high: high,
                    low: low,
                    condition: index == 1 ? .snow : .cloudy,
                    precipitationProbability: precipitation,
                    isMockData: true
                )
            )
        }
        return days
    }

    public static let airQuality = AirQuality(
        locationId: saltLakeCity.id,
        observedAt: observedAt,
        aqi: 54,
        category: .moderate,
        primaryPollutant: "PM2.5",
        sourceLabel: "Local sample fixture",
        isMockData: true
    )

    public static let incident = TrafficIncident(
        id: "slc-closure",
        locationId: saltLakeCity.id,
        title: "Parleys sample closure",
        description: "Fictional closure used to demonstrate incident detail.",
        road: "I-80",
        area: "Parleys Canyon",
        severity: .critical,
        incidentType: .closure,
        status: .active,
        latitude: 40.748,
        longitude: -111.78,
        reportedAt: observedAt,
        updatedAt: observedAt,
        isMockData: true
    )

    public static let moderateIncident = TrafficIncident(
        id: "slc-roadwork",
        locationId: saltLakeCity.id,
        title: "5400 South sample roadwork",
        description: "Fictional roadwork.",
        road: "5400 South",
        area: "Murray",
        severity: .moderate,
        incidentType: .roadwork,
        status: .scheduled,
        latitude: 40.655,
        longitude: -111.89,
        reportedAt: observedAt.addingTimeInterval(-3600),
        updatedAt: observedAt.addingTimeInterval(-1800),
        isMockData: true
    )

    public static let lowIncident = TrafficIncident(
        id: "slc-slowdown",
        locationId: saltLakeCity.id,
        title: "I-15 sample slowdown",
        description: "Fictional congestion.",
        road: "I-15",
        area: "Downtown",
        severity: .low,
        incidentType: .congestion,
        status: .active,
        latitude: 40.76,
        longitude: -111.91,
        reportedAt: observedAt.addingTimeInterval(-7200),
        updatedAt: observedAt.addingTimeInterval(-600),
        isMockData: true
    )

    public static let road = RoadCondition(
        id: "slc-road-1",
        locationId: saltLakeCity.id,
        roadName: "I-80",
        area: "Parleys Canyon",
        condition: .icy,
        description: "Sample icy patches in the canyon.",
        updatedAt: observedAt,
        isMockData: true
    )

    public static let trafficSummary = TrafficSummary(
        headline: "3 sample incidents",
        incidentCount: 3,
        highestSeverity: .critical,
        topIncidents: [incident, moderateIncident, lowIncident],
        roadConditionHeadline: "1 sample road advisory"
    )

    public static let unreadAlert = LocalAlert(
        id: "slc-alert-weather",
        locationId: saltLakeCity.id,
        title: "Sample valley snow",
        summary: "Fictional snow wording for the Salt Lake valley.",
        details: "This sample alert describes possible snow. It is not a live warning.",
        category: .snow,
        severity: .warning,
        area: "Salt Lake City",
        createdAt: observedAt,
        expiresAt: observedAt.addingTimeInterval(86_400),
        isRead: false,
        isMockData: true
    )

    public static let readAlert = LocalAlert(
        id: "slc-alert-community",
        locationId: saltLakeCity.id,
        title: "Sample library hours",
        summary: "Fictional community notice.",
        details: "Sample community announcement. Not an official notice.",
        category: .community,
        severity: .info,
        area: "Salt Lake City",
        createdAt: observedAt.addingTimeInterval(-7200),
        expiresAt: nil,
        isRead: true,
        isMockData: true
    )

    public static let park = LocalPlace(
        id: "slc-liberty-park",
        locationId: saltLakeCity.id,
        name: "Liberty Park",
        category: .parks,
        address: "600 E 900 S, Salt Lake City",
        latitude: 40.746,
        longitude: -111.874,
        description: "Sample park listing near the selected city center.",
        isMockData: true
    )

    public static let library = LocalPlace(
        id: "slc-library",
        locationId: saltLakeCity.id,
        name: "Salt Lake City Public Library",
        category: .libraries,
        address: "210 E 400 S, Salt Lake City",
        latitude: 40.760,
        longitude: -111.885,
        description: "Sample library listing.",
        isMockData: true
    )

    public static let hospital = LocalPlace(
        id: "slc-clinic",
        locationId: saltLakeCity.id,
        name: "Sample Valley Clinic",
        category: .hospitals,
        address: "100 S State St, Salt Lake City",
        latitude: 40.767,
        longitude: -111.888,
        description: "Sample clinic listing. Not for emergencies.",
        isMockData: true
    )

    public static let commute = SavedCommute(
        id: "slc-commute-downtown",
        locationId: saltLakeCity.id,
        name: "Downtown sample",
        origin: "Sugar House",
        destination: "Downtown",
        sampleNote: "Sample route only. UtahLife does not calculate live travel times."
    )

    public static let camera = MockCamera(
        id: "slc-camera-i15",
        locationId: saltLakeCity.id,
        name: "I-15 sample camera",
        road: "I-15",
        area: "Downtown",
        sampleStatus: "Sample still"
    )

    public static func dashboard(greeting: String = "Good morning") -> DashboardData {
        DashboardData(
            location: saltLakeCity,
            greeting: greeting,
            weather: weather,
            hourly: hourly,
            airQuality: airQuality,
            traffic: trafficSummary,
            alerts: [unreadAlert, readAlert],
            loadedAt: observedAt
        )
    }
}
