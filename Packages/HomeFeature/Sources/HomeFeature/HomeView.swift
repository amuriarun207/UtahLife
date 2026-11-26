import CoreKit
import DesignSystem
import DomainKit
import FeatureUI
import SwiftUI

public struct HomeView: View {
    @ObservedObject private var store: HomeStore
    private let onNavigate: (HomeNavigation) -> Void
    private let onSelectLocation: (Location) -> Void

    public init(
        store: HomeStore,
        onNavigate: @escaping (HomeNavigation) -> Void,
        onSelectLocation: @escaping (Location) -> Void
    ) {
        self.store = store
        self.onNavigate = onNavigate
        self.onSelectLocation = onSelectLocation
    }

    public var body: some View {
        ScrollView {
            ReadableScreen {
                VStack(alignment: .leading, spacing: Spacing.large) {
                    header
                    MockDataBanner()
                    content
                    if store.state.isRefreshing {
                        Text("Refreshing sample data")
                            .font(UtahFont.caption)
                            .foregroundStyle(UtahColor.secondaryText)
                    }
                }
                .padding(Spacing.large)
            }
        }
        .background(UtahColor.groupedBackground)
        .navigationTitle("Home")
        .accessibilityIdentifier(A11yID.screenHome)
        .refreshable { await store.send(.refresh) }
        .task { await store.send(.onAppear) }
        .sheet(isPresented: locationPresented) {
            LocationSelector(
                locations: store.state.locations,
                selectedID: store.state.selectedLocation.id,
                onSelect: { location in
                    onSelectLocation(location)
                }
            )
        }
        .onChange(of: store.state.navigation) { _, navigation in
            guard let navigation else { return }
            onNavigate(navigation)
            Task { await store.send(.navigationConsumed) }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(store.state.greeting.isEmpty ? "UtahLife" : store.state.greeting)
                .font(UtahFont.largeTitle)
            Button {
                Task { await store.send(.showLocationPicker) }
            } label: {
                Label(store.state.selectedLocation.displayName, systemImage: "mappin.and.ellipse")
                    .font(UtahFont.headline)
            }
            .accessibilityIdentifier(A11yID.homeLocationButton)
            Text("Sample location. Location permission is not requested.")
                .font(UtahFont.caption)
                .foregroundStyle(UtahColor.secondaryText)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state.weather {
        case .idle, .loading:
            LoadingStateView(title: "Loading sample dashboard")
        case let .failed(error):
            ErrorStateView(message: error.message) {
                Task { await store.send(.retry) }
            }
        case .empty:
            EmptyStateView(
                title: "No sample data",
                message: "The sample catalog has nothing to show for \(store.state.selectedLocation.city).",
                symbol: "tray"
            )
        case .loaded:
            dashboard
        }
    }

    private var dashboard: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            if let weather = store.state.weather.value {
                WeatherSummaryCard(weather: weather, timeZone: store.state.selectedLocation.timeZone) {
                    Task { await store.send(.weatherTapped) }
                }
                .accessibilityIdentifier(A11yID.homeWeatherCard)
            }
            if case let .loaded(hourly) = store.state.hourly {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    SectionHeader("Hourly sample")
                    HourlyStrip(forecasts: Array(hourly.prefix(8)), timeZone: store.state.selectedLocation.timeZone)
                }
            }
            AdaptiveColumnGrid {
                if let airQuality = store.state.airQuality.value {
                    AirQualityCard(airQuality: airQuality, timeZone: store.state.selectedLocation.timeZone) {
                        Task { await store.send(.airQualityTapped) }
                    }
                    .accessibilityIdentifier(A11yID.homeAirQualityCard)
                }
                if let traffic = store.state.traffic.value {
                    trafficCard(traffic)
                }
            }
            alertsSection
            quickActions
        }
    }

    private func trafficCard(_ traffic: TrafficSummary) -> some View {
        Button {
            Task { await store.send(.trafficTapped) }
        } label: {
            UtahCard {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    HStack {
                        Text("Travel")
                            .font(UtahFont.headline)
                        Spacer()
                        if let severity = traffic.highestSeverity {
                            StatusPill(title: severity.title, symbol: severity.symbolName, tone: .warning)
                        }
                    }
                    Text(traffic.headline)
                        .font(UtahFont.title)
                    Text(traffic.roadConditionHeadline)
                        .font(UtahFont.callout)
                        .foregroundStyle(UtahColor.secondaryText)
                    ForEach(traffic.topIncidents) { incident in
                        Text("\(incident.severity.title) · \(incident.title)")
                            .font(UtahFont.caption)
                    }
                    Text("Sample incidents. Not live traffic.")
                        .font(UtahFont.caption)
                        .foregroundStyle(UtahColor.secondaryText)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(A11yID.homeTrafficCard)
    }

    @ViewBuilder
    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            SectionHeader("Alerts", actionTitle: "See all") {
                Task { await store.send(.seeAllAlerts) }
            }
            .accessibilityIdentifier(A11yID.homeSeeAllAlerts)
            switch store.state.alerts {
            case .idle, .loading:
                LoadingStateView(title: "Loading sample alerts")
            case .empty:
                Text("No sample alerts for this location.")
                    .font(UtahFont.callout)
                    .foregroundStyle(UtahColor.secondaryText)
            case let .failed(error):
                Text(error.message)
                    .font(UtahFont.callout)
            case let .loaded(alerts):
                ForEach(alerts) { alert in
                    Button {
                        Task { await store.send(.alertTapped(alert.id)) }
                    } label: {
                        UtahCard { LocalAlertRow(alert: alert) }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(alert.id == alerts.first?.id ? A11yID.homeAlertPreview : A11yID.alertRow(alert.id))
                }
            }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            SectionHeader("Quick actions")
            HStack(spacing: Spacing.medium) {
                QuickActionButton(title: "Travel", symbol: "car", identifier: A11yID.homeQuickTravel) {
                    Task { await store.send(.seeAllTravel) }
                }
                QuickActionButton(title: "Environment", symbol: "cloud.sun", identifier: A11yID.homeQuickEnvironment) {
                    Task { await store.send(.weatherTapped) }
                }
                QuickActionButton(title: "Explore", symbol: "map", identifier: A11yID.homeQuickExplore) {
                    Task { await store.send(.seeAllExplore) }
                }
            }
        }
    }

    private var locationPresented: Binding<Bool> {
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
        HomeView(store: .preview(populated), onNavigate: { _ in }, onSelectLocation: { _ in })
    }
}

#Preview("Loading") {
    NavigationStack {
        HomeView(store: .preview(loading), onNavigate: { _ in }, onSelectLocation: { _ in })
    }
}

#Preview("Error") {
    NavigationStack {
        HomeView(store: .preview(failed), onNavigate: { _ in }, onSelectLocation: { _ in })
    }
}

#Preview("Empty") {
    NavigationStack {
        HomeView(store: .preview(empty), onNavigate: { _ in }, onSelectLocation: { _ in })
    }
}

#Preview("Dark") {
    NavigationStack {
        HomeView(store: .preview(populated), onNavigate: { _ in }, onSelectLocation: { _ in })
    }
    .preferredColorScheme(.dark)
}

#Preview("Large text") {
    NavigationStack {
        HomeView(store: .preview(populated), onNavigate: { _ in }, onSelectLocation: { _ in })
    }
    .environment(\.dynamicTypeSize, .accessibility3)
}

private var populated: HomeState {
    let data = PreviewCatalog.dashboard()
    return HomeReducer.reduce(
        HomeState(selectedLocation: PreviewCatalog.saltLakeCity, locations: [PreviewCatalog.saltLakeCity, PreviewCatalog.westJordan]),
        .dashboardLoaded(data)
    )
}

private var loading: HomeState {
    HomeReducer.reduce(
        HomeState(selectedLocation: PreviewCatalog.saltLakeCity, locations: [PreviewCatalog.saltLakeCity]),
        .loadStarted
    )
}

private var failed: HomeState {
    HomeReducer.reduce(
        HomeState(selectedLocation: PreviewCatalog.saltLakeCity, locations: [PreviewCatalog.saltLakeCity]),
        .dashboardFailed(.unavailable("Sample data could not be loaded."))
    )
}

private var empty: HomeState {
    HomeReducer.reduce(
        HomeState(selectedLocation: PreviewCatalog.saltLakeCity, locations: [PreviewCatalog.saltLakeCity]),
        .dashboardEmpty
    )
}
