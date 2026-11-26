import CoreKit
import DesignSystem
import DomainKit
import FeatureUI
import SwiftUI

public struct AlertsView: View {
    @ObservedObject private var store: AlertsStore
    private let onSelectLocation: (Location) -> Void
    @State private var showLocations = false

    public init(store: AlertsStore, onSelectLocation: @escaping (Location) -> Void) {
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
        .navigationTitle("Alerts")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Preferences") { Task { await store.send(.showPreferences) } }
                    .accessibilityIdentifier(A11yID.alertsPreferences)
            }
        }
        .accessibilityIdentifier(A11yID.screenAlerts)
        .refreshable { await store.send(.refresh) }
        .task { await store.send(.onAppear) }
        .sheet(isPresented: $showLocations) {
            LocationSelector(
                locations: store.state.locations,
                selectedID: store.state.selectedLocation.id,
                onSelect: { location in
                    onSelectLocation(location)
                    showLocations = false
                }
            )
        }
        .sheet(item: selectedAlert) { alert in
            AlertDetailView(alert: alert, timeZone: store.state.selectedLocation.timeZone) {
                Task { await store.send(.markRead(alert.id)) }
            }
        }
        .sheet(isPresented: preferencesPresented) {
            PreferencesView(preferences: store.state.preferences) { intent in
                Task { await store.send(intent) }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(store.state.selectedLocation.displayName)
                .font(UtahFont.title)
            Button("Change sample location") { showLocations = true }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.small) {
                    ForEach(AlertCategory.allCases) { category in
                        CategoryChip(title: category.title, isSelected: store.state.categories.contains(category)) {
                            Task { await store.send(.toggleCategory(category)) }
                        }
                        .accessibilityIdentifier(A11yID.alertCategory(category.rawValue))
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.small) {
                    ForEach(AlertSeverity.allCases, id: \.self) { severity in
                        CategoryChip(title: severity.title, isSelected: store.state.severities.contains(severity)) {
                            Task { await store.send(.toggleSeverity(severity)) }
                        }
                    }
                }
            }
            HStack {
                Button("Mark all read") { Task { await store.send(.markAllRead) } }
                    .accessibilityIdentifier(A11yID.alertsMarkAll)
                Button("Clear filters") { Task { await store.send(.clearFilters) } }
            }
            .font(UtahFont.callout.weight(.semibold))
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state.alerts {
        case .idle, .loading:
            LoadingStateView(title: "Loading sample alerts")
        case let .failed(error):
            ErrorStateView(message: error.message) {
                Task { await store.send(.retry) }
            }
        case .empty:
            EmptyStateView(
                title: "No sample alerts",
                message: "The sample catalog has no alerts for \(store.state.selectedLocation.city).",
                symbol: "bell.slash"
            )
        case .loaded:
            if store.state.visibleAlerts.isEmpty {
                EmptyStateView(
                    title: "No matches",
                    message: "No sample alerts match these filters.",
                    symbol: "line.3.horizontal.decrease.circle"
                )
            } else {
                ForEach(store.state.visibleAlerts) { alert in
                    Button {
                        Task { await store.send(.selectAlert(alert.id)) }
                    } label: {
                        UtahCard { LocalAlertRow(alert: alert) }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(A11yID.alertRow(alert.id))
                }
            }
        }
    }

    private var selectedAlert: Binding<LocalAlert?> {
        Binding(
            get: {
                guard let id = store.state.selectedAlertID else { return nil }
                return store.state.alerts.value?.first { $0.id == id }
            },
            set: { alert in Task { await store.send(.selectAlert(alert?.id)) } }
        )
    }

    private var preferencesPresented: Binding<Bool> {
        Binding(
            get: { store.state.isPreferencesPresented },
            set: { isPresented in
                Task { await store.send(isPresented ? .showPreferences : .dismissPreferences) }
            }
        )
    }
}

private struct AlertDetailView: View {
    let alert: LocalAlert
    let timeZone: TimeZone
    let markRead: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    MockDataBanner()
                    Text(alert.isRead ? "Read" : "Unread")
                        .font(UtahFont.caption.weight(.semibold))
                    StatusPill(title: alert.severity.title, symbol: alert.severity.symbolName, tone: .warning)
                    Text(alert.title).font(UtahFont.largeTitle)
                    Text(alert.summary).font(UtahFont.title)
                    Text(alert.details)
                    Text("\(alert.category.title) · \(alert.area)")
                    LastUpdatedLabel(ObservationTimestampFormatter.string(for: alert.createdAt, timeZone: timeZone))
                    if let expiresAt = alert.expiresAt {
                        Text("Sample expiry \(ObservationTimestampFormatter.string(for: expiresAt, timeZone: timeZone))")
                            .font(UtahFont.caption)
                            .foregroundStyle(UtahColor.secondaryText)
                    }
                    if alert.isRead == false {
                        Button("Mark as read", action: markRead)
                            .buttonStyle(.borderedProminent)
                            .tint(UtahColor.accent)
                            .accessibilityIdentifier(A11yID.alertsMarkRead)
                    }
                }
                .padding(Spacing.large)
            }
            .navigationTitle("Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
}

private struct PreferencesView: View {
    let preferences: NotificationPreferences
    let send: (AlertsIntent) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Sample alerts enabled", isOn: Binding(
                        get: { preferences.masterEnabled },
                        set: { send(.setMasterEnabled($0)) }
                    ))
                    .accessibilityIdentifier(A11yID.alertsPreferenceMaster)
                    Text(SampleCopy.notificationDisclaimer)
                        .font(UtahFont.caption)
                        .foregroundStyle(UtahColor.secondaryText)
                }
                Section("Categories") {
                    ForEach(AlertCategory.allCases) { category in
                        Toggle(category.title, isOn: Binding(
                            get: { preferences.categories[category] ?? false },
                            set: { send(.setCategoryEnabled(category, $0)) }
                        ))
                    }
                }
            }
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview("Unread and read") {
    NavigationStack { AlertsView(store: .preview(populated), onSelectLocation: { _ in }) }
}

#Preview("Dark") {
    NavigationStack { AlertsView(store: .preview(populated), onSelectLocation: { _ in }) }
        .preferredColorScheme(.dark)
}

private var populated: AlertsState {
    AlertsReducer.reduce(
        AlertsState(selectedLocation: PreviewCatalog.saltLakeCity, locations: [PreviewCatalog.saltLakeCity]),
        .loaded([PreviewCatalog.unreadAlert, PreviewCatalog.readAlert])
    )
}
