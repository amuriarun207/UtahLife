import CoreKit
import DesignSystem
import DomainKit
import FeatureUI
import SwiftUI

public struct EnvironmentView: View {
    @ObservedObject private var store: EnvironmentStore
    private let onSelectLocation: (Location) -> Void

    public init(store: EnvironmentStore, onSelectLocation: @escaping (Location) -> Void) {
        self.store = store
        self.onSelectLocation = onSelectLocation
    }

    public var body: some View {
        ScrollView {
            ReadableScreen {
                VStack(alignment: .leading, spacing: Spacing.large) {
                    header
                    MockDataBanner()
                    content
                }
                .padding(Spacing.large)
            }
        }
        .background(UtahColor.groupedBackground)
        .navigationTitle("Environment")
        .accessibilityIdentifier(A11yID.screenEnvironment)
        .refreshable { await store.send(.refresh) }
        .task { await store.send(.onAppear) }
        .sheet(isPresented: pickerPresented) {
            LocationSelector(
                locations: store.state.locations,
                selectedID: store.state.selectedLocation.id,
                onSelect: onSelectLocation
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Picker("Section", selection: section) {
                ForEach(EnvironmentFocus.allCases, id: \.self) { focus in
                    Text(focus.title).tag(focus)
                }
            }
            .pickerStyle(.segmented)
            Button {
                Task { await store.send(.showLocationPicker) }
            } label: {
                Label(store.state.selectedLocation.displayName, systemImage: "mappin.and.ellipse")
            }
            .accessibilityIdentifier("environment.locationButton")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state.snapshot {
        case .idle, .loading:
            LoadingStateView(title: "Loading sample conditions")
        case let .failed(error):
            ErrorStateView(message: error.message) {
                Task { await store.send(.retry) }
            }
        case .empty:
            EmptyStateView(
                title: "No sample conditions",
                message: "No sample weather or air quality is available for \(store.state.selectedLocation.city).",
                symbol: "cloud"
            )
        case let .loaded(snapshot):
            loaded(snapshot)
        }
    }

    private func loaded(_ snapshot: EnvironmentSnapshot) -> some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            AdaptivePair {
                weatherSection(snapshot)
            } secondary: {
                airSection(snapshot.airQuality)
            }
            if store.state.section == .weather {
                hourlySection(snapshot)
                dailySection(snapshot)
            }
        }
    }

    private func weatherSection(_ snapshot: EnvironmentSnapshot) -> some View {
        UtahCard {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Current sample")
                    .font(UtahFont.headline)
                Text(snapshot.weather.temperature.display)
                    .font(UtahFont.metric)
                Text("Feels like \(snapshot.weather.feelsLike.display) · \(snapshot.weather.condition.title)")
                AdaptiveColumnGrid(minItemWidth: 140) {
                    MetricTile(title: "Humidity", value: snapshot.weather.humidity.display, symbol: "humidity")
                    MetricTile(title: "Wind", value: snapshot.weather.windSpeed.display, symbol: "wind")
                    MetricTile(title: "Precipitation", value: snapshot.weather.precipitationProbability.display, symbol: "cloud.rain")
                    MetricTile(title: "High / low", value: "\(snapshot.weather.high.display) / \(snapshot.weather.low.display)", symbol: "thermometer")
                }
                LastUpdatedLabel(ObservationTimestampFormatter.string(for: snapshot.weather.observedAt, timeZone: store.state.selectedLocation.timeZone))
            }
        }
    }

    private func hourlySection(_ snapshot: EnvironmentSnapshot) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            SectionHeader("Hourly forecast")
            HourlyStrip(forecasts: snapshot.hourly, timeZone: store.state.selectedLocation.timeZone)
        }
    }

    private func dailySection(_ snapshot: EnvironmentSnapshot) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            SectionHeader("Seven-day forecast")
            ForEach(snapshot.daily) { day in
                Button {
                    Task { await store.send(.selectDay(day.id)) }
                } label: {
                    ForecastDayRow(
                        day: day,
                        timeZone: store.state.selectedLocation.timeZone,
                        isSelected: store.state.selectedDayID == day.id
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(A11yID.forecastRow(day.id))
            }
            if let selected = snapshot.daily.first(where: { $0.id == store.state.selectedDayID }) {
                UtahCard {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Selected sample day")
                            .font(UtahFont.headline)
                        Text(ObservationTimestampFormatter.fullDay(for: selected.date, timeZone: store.state.selectedLocation.timeZone))
                        Text("\(selected.condition.title). High \(selected.high.display), low \(selected.low.display). Precipitation chance \(selected.precipitationProbability.display).")
                        Text("Sample forecast. Not a live outlook.")
                            .font(UtahFont.caption)
                            .foregroundStyle(UtahColor.secondaryText)
                    }
                }
                .accessibilityIdentifier("environment.selectedDay")
            }
        }
    }

    private func airSection(_ airQuality: AirQuality) -> some View {
        UtahCard {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Air quality")
                    .font(UtahFont.headline)
                Text("\(airQuality.aqi)")
                    .font(UtahFont.metric)
                StatusPill(title: airQuality.category.title, symbol: airQuality.category.symbolName, tone: .info)
                Text("Primary pollutant \(airQuality.primaryPollutant)")
                Text(airQuality.sourceLabel)
                    .font(UtahFont.caption)
                    .foregroundStyle(UtahColor.secondaryText)
                Button(store.state.isAQIExpanded ? "Hide explanation" : "Explain this index") {
                    Task { await store.send(.toggleAQIExplanation) }
                }
                .accessibilityIdentifier(A11yID.environmentAQIDisclosure)
                if store.state.isAQIExpanded {
                    Text(airQuality.category.explanation)
                    Text(airQuality.category.guidance)
                    Text(SampleCopy.healthDisclaimer)
                        .font(UtahFont.caption)
                        .foregroundStyle(UtahColor.secondaryText)
                        .accessibilityIdentifier(A11yID.environmentAQIExplanation)
                }
                LastUpdatedLabel(ObservationTimestampFormatter.string(for: airQuality.observedAt, timeZone: store.state.selectedLocation.timeZone))
            }
        }
    }

    private var section: Binding<EnvironmentFocus> {
        Binding(
            get: { store.state.section },
            set: { focus in Task { await store.send(.selectSection(focus)) } }
        )
    }

    private var pickerPresented: Binding<Bool> {
        Binding(
            get: { store.state.isLocationPickerPresented },
            set: { isPresented in
                Task { await store.send(isPresented ? .showLocationPicker : .dismissLocationPicker) }
            }
        )
    }
}

#Preview("Populated") {
    NavigationStack {
        EnvironmentView(store: .preview(populated), onSelectLocation: { _ in })
    }
}

#Preview("Dark large text") {
    NavigationStack {
        EnvironmentView(store: .preview(populated), onSelectLocation: { _ in })
    }
    .preferredColorScheme(.dark)
    .environment(\.dynamicTypeSize, .accessibility2)
}

private var populated: EnvironmentState {
    let snapshot = EnvironmentSnapshot(
        weather: PreviewCatalog.weather,
        hourly: PreviewCatalog.hourly,
        daily: PreviewCatalog.daily,
        airQuality: PreviewCatalog.airQuality
    )
    return EnvironmentReducer.reduce(
        EnvironmentState(selectedLocation: PreviewCatalog.saltLakeCity, locations: [PreviewCatalog.saltLakeCity]),
        .loaded(snapshot)
    )
}
