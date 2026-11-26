import CoreKit
import DesignSystem
import DomainKit
import SwiftUI

public struct LocationSelector: View {
    private let locations: [Location]
    private let selectedID: String
    private let onSelect: (Location) -> Void

    public init(locations: [Location], selectedID: String, onSelect: @escaping (Location) -> Void) {
        self.locations = locations
        self.selectedID = selectedID
        self.onSelect = onSelect
    }

    public var body: some View {
        NavigationStack {
            List(locations) { location in
                Button {
                    onSelect(location)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xSmall) {
                            Text(location.city)
                                .font(UtahFont.body)
                                .foregroundStyle(UtahColor.primaryText)
                            Text(location.displayName)
                                .font(UtahFont.caption)
                                .foregroundStyle(UtahColor.secondaryText)
                        }
                        Spacer()
                        if location.id == selectedID {
                            Image(systemName: "checkmark")
                                .foregroundStyle(UtahColor.accent)
                                .accessibilityLabel("Selected")
                        }
                    }
                }
                .accessibilityIdentifier(A11yID.locationRow(location.id))
            }
            .navigationTitle("Sample location")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

public struct WeatherSummaryCard: View {
    private let weather: Weather
    private let timeZone: TimeZone
    private let action: () -> Void

    public init(weather: Weather, timeZone: TimeZone, action: @escaping () -> Void) {
        self.weather = weather
        self.timeZone = timeZone
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            UtahCard {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    HStack {
                        Label("Weather", systemImage: weather.condition.symbolName)
                            .font(UtahFont.headline)
                        Spacer()
                        StatusPill(title: weather.condition.title, symbol: weather.condition.symbolName, tone: .info)
                    }
                    Text(weather.temperature.display)
                        .font(UtahMetric.font)
                        .foregroundStyle(UtahColor.primaryText)
                    Text("Feels like \(weather.feelsLike.display)")
                        .font(UtahFont.body)
                    Text("High \(weather.high.display) · Low \(weather.low.display)")
                        .font(UtahFont.callout)
                        .foregroundStyle(UtahColor.secondaryText)
                    LastUpdatedLabel(ObservationTimestampFormatter.string(for: weather.observedAt, timeZone: timeZone))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the environment sample")
    }
}

enum UtahMetric {
    static let font = Font.system(.largeTitle, design: .rounded).weight(.semibold)
}

public struct HourlyStrip: View {
    private let forecasts: [HourlyForecast]
    private let timeZone: TimeZone

    public init(forecasts: [HourlyForecast], timeZone: TimeZone) {
        self.forecasts = forecasts
        self.timeZone = timeZone
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.small) {
                ForEach(forecasts) { hour in
                    VStack(spacing: Spacing.xSmall) {
                        Text(ObservationTimestampFormatter.time(for: hour.dateTime, timeZone: timeZone))
                            .font(UtahFont.caption)
                        Image(systemName: hour.condition.symbolName)
                            .accessibilityHidden(true)
                        Text(hour.temperature.display)
                            .font(UtahFont.callout.weight(.semibold))
                    }
                    .frame(minWidth: 68)
                    .padding(.vertical, Spacing.small)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(ObservationTimestampFormatter.time(for: hour.dateTime, timeZone: timeZone)), \(hour.temperature.display), \(hour.condition.title), \(hour.precipitationProbability.display) chance of precipitation. Sample forecast.")
                }
            }
        }
    }
}

public struct AirQualityCard: View {
    private let airQuality: AirQuality
    private let timeZone: TimeZone
    private let action: () -> Void

    public init(airQuality: AirQuality, timeZone: TimeZone, action: @escaping () -> Void) {
        self.airQuality = airQuality
        self.timeZone = timeZone
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            UtahCard {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    HStack {
                        Text("Air quality")
                            .font(UtahFont.headline)
                        Spacer()
                        StatusPill(
                            title: airQuality.category.title,
                            symbol: airQuality.category.symbolName,
                            tone: tone(for: airQuality.category)
                        )
                    }
                    Text("\(airQuality.aqi)")
                        .font(UtahMetric.font)
                    Text("Primary pollutant \(airQuality.primaryPollutant)")
                        .font(UtahFont.callout)
                    Text(airQuality.sourceLabel)
                        .font(UtahFont.caption)
                        .foregroundStyle(UtahColor.secondaryText)
                    LastUpdatedLabel(ObservationTimestampFormatter.string(for: airQuality.observedAt, timeZone: timeZone))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens air-quality sample details")
    }

    private func tone(for category: AQICategory) -> StatusTone {
        switch category {
        case .good: return .success
        case .moderate: return .warning
        case .unhealthyForSensitiveGroups, .unhealthy: return .warning
        case .veryUnhealthy, .hazardous: return .critical
        }
    }
}

public struct TrafficIncidentRow: View {
    private let incident: TrafficIncident

    public init(incident: TrafficIncident) {
        self.incident = incident
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(alignment: .firstTextBaseline) {
                Text(incident.title)
                    .font(UtahFont.body.weight(.semibold))
                Spacer(minLength: Spacing.small)
                StatusPill(title: incident.severity.title, symbol: incident.severity.symbolName, tone: tone)
            }
            Label(incident.incidentType.title, systemImage: incident.incidentType.symbolName)
                .font(UtahFont.caption)
                .foregroundStyle(UtahColor.secondaryText)
            Text("\(incident.road) · \(incident.area)")
                .font(UtahFont.callout)
            Text("Status \(incident.status.title) · Sample data")
                .font(UtahFont.caption)
                .foregroundStyle(UtahColor.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(A11yID.incidentRow(incident.id))
    }

    private var tone: StatusTone {
        switch incident.severity {
        case .low: return .info
        case .moderate: return .warning
        case .high, .critical: return .critical
        }
    }
}

public struct LocalAlertRow: View {
    private let alert: LocalAlert

    public init(alert: LocalAlert) {
        self.alert = alert
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(alignment: .firstTextBaseline) {
                Text(alert.title)
                    .font(alert.isRead ? UtahFont.body : UtahFont.body.weight(.semibold))
                Spacer(minLength: Spacing.small)
                Text(alert.isRead ? "Read" : "Unread")
                    .font(UtahFont.caption.weight(.semibold))
                    .foregroundStyle(UtahColor.secondaryText)
            }
            Text(alert.summary)
                .font(UtahFont.callout)
                .foregroundStyle(UtahColor.secondaryText)
                .lineLimit(2)
            HStack {
                StatusPill(title: alert.severity.title, symbol: alert.severity.symbolName, tone: tone)
                Text(alert.category.title)
                    .font(UtahFont.caption)
                    .foregroundStyle(UtahColor.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(A11yID.alertRow(alert.id))
    }

    private var tone: StatusTone {
        switch alert.severity {
        case .info: return .info
        case .advisory: return .warning
        case .warning, .critical: return .critical
        }
    }
}
