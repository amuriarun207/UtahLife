import CoreKit
import DesignSystem
import DomainKit
import FeatureUI
import SwiftUI

public struct TravelView: View {
    @ObservedObject private var store: TravelStore
    private let onSelectLocation: (Location) -> Void
    @State private var width: CGFloat = 0
    @State private var showLocations = false

    public init(store: TravelStore, onSelectLocation: @escaping (Location) -> Void) {
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
        .navigationTitle("Travel")
        .accessibilityIdentifier(A11yID.screenTravel)
        .refreshable { await store.send(.refresh) }
        .task { await store.send(.onAppear) }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
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
        .sheet(item: selectedIncident) { incident in
            IncidentDetailView(incident: incident, timeZone: store.state.selectedLocation.timeZone)
        }
        .sheet(item: selectedCommute) { commute in
            CommuteDetailView(commute: commute)
        }
        .sheet(item: selectedCamera) { camera in
            CameraDetailView(camera: camera)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Button {
                showLocations = true
            } label: {
                Label(store.state.selectedLocation.displayName, systemImage: "mappin.and.ellipse")
                    .font(UtahFont.title)
            }
            Text("Example road conditions. Not live traffic.")
                .font(UtahFont.caption)
                .foregroundStyle(UtahColor.secondaryText)
            Picker("Presentation", selection: presentation) {
                Text("List").tag(TravelPresentation.list)
                Text("Map").tag(TravelPresentation.map)
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier(store.state.presentation == .map ? A11yID.travelMap : A11yID.travelList)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state.overview {
        case .idle, .loading:
            LoadingStateView(title: "Loading sample travel")
        case let .failed(error):
            ErrorStateView(message: error.message) {
                Task { await store.send(.retry) }
            }
        case .empty:
            EmptyStateView(
                title: "No sample incidents",
                message: "The sample catalog has no road incidents for \(store.state.selectedLocation.city).",
                symbol: "car"
            )
        case let .loaded(overview):
            loaded(overview)
        }
    }

    private func loaded(_ overview: TravelOverview) -> some View {
        let list = incidentColumn(overview)
        let map = mapColumn(overview)
        return VStack(alignment: .leading, spacing: Spacing.large) {
            summary(overview)
            filters
            if width >= 760 {
                AdaptivePair { list } secondary: { map.frame(minHeight: 320) }
            } else if store.state.presentation == .map {
                map.frame(minHeight: 320)
            } else {
                list
            }
            roadSection(overview)
            commuteSection(overview)
            cameraSection(overview)
        }
    }

    private func summary(_ overview: TravelOverview) -> some View {
        UtahCard {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text(overview.summary.headline)
                    .font(UtahFont.title)
                Text(overview.summary.roadConditionHeadline)
                if let severity = overview.summary.highestSeverity {
                    StatusPill(title: "Highest \(severity.title)", symbol: severity.symbolName, tone: .warning)
                }
            }
        }
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            SectionHeader("Severity", actionTitle: "Clear") {
                Task { await store.send(.clearFilters) }
            }
            chipScroll {
                ForEach(IncidentSeverity.allCases, id: \.self) { severity in
                    CategoryChip(title: severity.title, isSelected: store.state.severityFilter.contains(severity)) {
                        Task { await store.send(.toggleSeverity(severity)) }
                    }
                    .accessibilityIdentifier(A11yID.travelSeverity(severity.rawValue))
                }
            }
            Text("Type")
                .font(UtahFont.headline)
            chipScroll {
                ForEach(IncidentType.allCases, id: \.self) { type in
                    CategoryChip(title: type.title, isSelected: store.state.typeFilter.contains(type)) {
                        Task { await store.send(.toggleType(type)) }
                    }
                    .accessibilityIdentifier(A11yID.travelType(type.rawValue))
                }
            }
        }
    }

    private func incidentColumn(_ overview: TravelOverview) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            SectionHeader("Incidents")
            if store.state.visibleIncidents.isEmpty {
                Text("No sample incidents match these filters.")
                    .font(UtahFont.callout)
                    .foregroundStyle(UtahColor.secondaryText)
            } else {
                ForEach(store.state.visibleIncidents) { incident in
                    Button {
                        Task { await store.send(.selectIncident(incident.id)) }
                    } label: {
                        UtahCard { TrafficIncidentRow(incident: incident) }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func mapColumn(_ overview: TravelOverview) -> some View {
        SampleMap(
            points: overview.incidents.map {
                SamplePoint(id: $0.id, title: $0.title, latitude: $0.latitude, longitude: $0.longitude, symbol: $0.incidentType.symbolName)
            },
            centerLatitude: store.state.selectedLocation.latitude,
            centerLongitude: store.state.selectedLocation.longitude,
            selection: incidentSelection,
            identifier: A11yID.travelMap
        )
        .frame(minHeight: 280)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
    }

    private func roadSection(_ overview: TravelOverview) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            SectionHeader("Road conditions")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: Spacing.medium) {
                    ForEach(overview.roadConditions) { condition in
                        RoadConditionCard(condition: condition, timeZone: store.state.selectedLocation.timeZone)
                            .frame(width: 260)
                    }
                }
            }
        }
    }

    private func commuteSection(_ overview: TravelOverview) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            SectionHeader("Saved commute examples")
            ForEach(overview.commutes) { commute in
                Button {
                    Task { await store.send(.selectCommute(commute.id)) }
                } label: {
                    UtahCard {
                        VStack(alignment: .leading, spacing: Spacing.xSmall) {
                            Text(commute.name).font(UtahFont.headline)
                            Text("\(commute.origin) to \(commute.destination)")
                            Text(SampleCopy.travelTimeDisclaimer)
                                .font(UtahFont.caption)
                                .foregroundStyle(UtahColor.secondaryText)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(A11yID.commuteRow(commute.id))
            }
        }
    }

    private func cameraSection(_ overview: TravelOverview) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            SectionHeader("Sample cameras")
            ForEach(overview.cameras) { camera in
                Button {
                    Task { await store.send(.selectCamera(camera.id)) }
                } label: {
                    UtahCard {
                        HStack {
                            Image(systemName: "video")
                                .accessibilityHidden(true)
                            VStack(alignment: .leading) {
                                Text(camera.name).font(UtahFont.headline)
                                Text("\(camera.road) · \(camera.sampleStatus)")
                                    .font(UtahFont.caption)
                                    .foregroundStyle(UtahColor.secondaryText)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(A11yID.cameraCard(camera.id))
            }
        }
    }

    private func chipScroll<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.small) { content() }
        }
    }

    private var presentation: Binding<TravelPresentation> {
        Binding(
            get: { store.state.presentation },
            set: { value in Task { await store.send(.presentation(value)) } }
        )
    }

    private var incidentSelection: Binding<String?> {
        Binding(
            get: { store.state.selectedIncidentID },
            set: { id in Task { await store.send(.selectIncident(id)) } }
        )
    }

    private var selectedIncident: Binding<TrafficIncident?> {
        Binding(
            get: { item(store.state.selectedIncidentID, in: store.state.overview.value?.incidents ?? []) },
            set: { value in Task { await store.send(.selectIncident(value?.id)) } }
        )
    }

    private var selectedCommute: Binding<SavedCommute?> {
        Binding(
            get: { item(store.state.selectedCommuteID, in: store.state.overview.value?.commutes ?? []) },
            set: { value in Task { await store.send(.selectCommute(value?.id)) } }
        )
    }

    private var selectedCamera: Binding<MockCamera?> {
        Binding(
            get: { item(store.state.selectedCameraID, in: store.state.overview.value?.cameras ?? []) },
            set: { value in Task { await store.send(.selectCamera(value?.id)) } }
        )
    }

    private func item<Item: Identifiable>(_ id: String?, in items: [Item]) -> Item? where Item.ID == String {
        guard let id else { return nil }
        return items.first { $0.id == id }
    }
}

private struct IncidentDetailView: View {
    let incident: TrafficIncident
    let timeZone: TimeZone

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    MockDataBanner()
                    StatusPill(title: incident.severity.title, symbol: incident.severity.symbolName, tone: .warning)
                    Text(incident.title).font(UtahFont.largeTitle)
                    Text(incident.description)
                    Text("\(incident.road) · \(incident.area)")
                    Text("Type \(incident.incidentType.title) · Status \(incident.status.title)")
                    LastUpdatedLabel(ObservationTimestampFormatter.string(for: incident.updatedAt, timeZone: timeZone))
                    Text("Reported \(ObservationTimestampFormatter.string(for: incident.reportedAt, timeZone: timeZone))")
                        .font(UtahFont.caption)
                        .foregroundStyle(UtahColor.secondaryText)
                }
                .padding(Spacing.large)
            }
            .navigationTitle("Incident")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct CommuteDetailView: View {
    let commute: SavedCommute

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text(commute.name).font(UtahFont.title)
                Text("\(commute.origin) to \(commute.destination)")
                Text(commute.sampleNote)
                Text(SampleCopy.travelTimeDisclaimer)
                    .foregroundStyle(UtahColor.secondaryText)
                Spacer()
            }
            .padding(Spacing.large)
            .navigationTitle("Sample commute")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct CameraDetailView: View {
    let camera: MockCamera

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.large) {
                Image(systemName: "video.slash")
                    .font(.largeTitle)
                    .foregroundStyle(UtahColor.secondaryText)
                    .accessibilityHidden(true)
                Text(camera.name).font(UtahFont.title)
                Text("\(camera.road) · \(camera.area)")
                Text(SampleCopy.cameraDisclaimer)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(UtahColor.secondaryText)
            }
            .padding(Spacing.large)
            .navigationTitle("Sample camera")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview("Incidents") {
    NavigationStack { TravelView(store: .preview(populated), onSelectLocation: { _ in }) }
}

#Preview("Empty") {
    NavigationStack { TravelView(store: .preview(TravelState(selectedLocation: PreviewCatalog.saltLakeCity, locations: [PreviewCatalog.saltLakeCity], overview: .empty)), onSelectLocation: { _ in }) }
}

private var populated: TravelState {
    let overview = TravelOverview(
        incidents: [PreviewCatalog.incident, PreviewCatalog.moderateIncident, PreviewCatalog.lowIncident],
        roadConditions: [PreviewCatalog.road],
        summary: PreviewCatalog.trafficSummary,
        commutes: [PreviewCatalog.commute],
        cameras: [PreviewCatalog.camera]
    )
    return TravelReducer.reduce(
        TravelState(selectedLocation: PreviewCatalog.saltLakeCity, locations: [PreviewCatalog.saltLakeCity]),
        .loaded(overview)
    )
}
