import CoreKit
import DesignSystem
import DomainKit
import FeatureUI
import SwiftUI

public struct ExploreView: View {
    @ObservedObject private var store: ExploreStore
    private let onSelectLocation: (Location) -> Void
    @State private var width: CGFloat = 0

    public init(store: ExploreStore, onSelectLocation: @escaping (Location) -> Void) {
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
        .navigationTitle("Explore")
        .accessibilityIdentifier(A11yID.screenExplore)
        .refreshable { await store.send(.refresh) }
        .task { await store.send(.onAppear) }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .sheet(isPresented: pickerPresented) {
            LocationSelector(
                locations: store.state.locations,
                selectedID: store.state.selectedLocation.id,
                onSelect: onSelectLocation
            )
        }
        .sheet(item: selectedPlace) { place in
            PlaceDetailView(place: place, location: store.state.selectedLocation)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Button {
                Task { await store.send(.showLocationPicker) }
            } label: {
                Label(store.state.selectedLocation.displayName, systemImage: "mappin.and.ellipse")
            }
            TextField("Search sample places", text: query)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier(A11yID.exploreSearch)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.small) {
                    ForEach(PlaceCategory.allCases) { category in
                        CategoryChip(title: category.title, isSelected: store.state.category == category) {
                            Task { await store.send(.selectCategory(category)) }
                        }
                        .accessibilityIdentifier(A11yID.exploreChip(category.rawValue))
                    }
                }
            }
            HStack {
                Picker("Presentation", selection: presentation) {
                    Text("List").tag(ExplorePresentation.list)
                    Text("Map").tag(ExplorePresentation.map)
                }
                .pickerStyle(.segmented)
                Button("Clear") { Task { await store.send(.clearFilters) } }
                    .accessibilityIdentifier(A11yID.exploreClear)
            }
            Text("Sample listings. Not a live directory.")
                .font(UtahFont.caption)
                .foregroundStyle(UtahColor.secondaryText)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state.places {
        case .idle, .loading:
            LoadingStateView(title: "Loading sample places")
        case let .failed(error):
            ErrorStateView(message: error.message) {
                Task { await store.send(.retry) }
            }
        case .empty:
            EmptyStateView(
                title: "No sample places",
                message: "The sample catalog has no places for \(store.state.selectedLocation.city).",
                symbol: "mappin.slash"
            )
        case .loaded:
            results
        }
    }

    @ViewBuilder
    private var results: some View {
        if store.state.visiblePlaces.isEmpty {
            EmptyStateView(
                title: "No matches",
                message: "No sample places match this search.",
                symbol: "magnifyingglass"
            )
        } else if width >= 760 {
            AdaptivePair { list } secondary: { map.frame(minHeight: 360) }
        } else if store.state.presentation == .map {
            map.frame(minHeight: 360)
        } else {
            list
        }
    }

    private var list: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            SectionHeader("Nearby sample places")
            ForEach(store.state.visiblePlaces) { place in
                Button {
                    Task { await store.send(.selectPlace(place.id)) }
                } label: {
                    UtahCard {
                        PlaceRow(place: place, distance: distance(for: place))
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityIdentifier(A11yID.exploreList)
    }

    private var map: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            SampleMap(
                points: store.state.visiblePlaces.map {
                    SamplePoint(id: $0.id, title: $0.name, latitude: $0.latitude, longitude: $0.longitude, symbol: $0.category.symbolName)
                },
                centerLatitude: store.state.selectedLocation.latitude,
                centerLongitude: store.state.selectedLocation.longitude,
                selection: highlightSelection,
                identifier: A11yID.exploreMap
            )
            .frame(minHeight: 280)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
            if let place = store.state.visiblePlaces.first(where: { $0.id == store.state.highlightedPlaceID }) {
                Button {
                    Task { await store.send(.selectPlace(place.id)) }
                } label: {
                    UtahCard { PlaceRow(place: place, distance: distance(for: place)) }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func distance(for place: LocalPlace) -> String {
        let miles = DistanceCalculator.miles(
            fromLatitude: store.state.selectedLocation.latitude,
            fromLongitude: store.state.selectedLocation.longitude,
            toLatitude: place.latitude,
            toLongitude: place.longitude
        )
        return DistanceCalculator.label(miles: miles)
    }

    private var query: Binding<String> {
        Binding(
            get: { store.state.query },
            set: { text in Task { await store.send(.queryChanged(text)) } }
        )
    }

    private var presentation: Binding<ExplorePresentation> {
        Binding(
            get: { store.state.presentation },
            set: { value in Task { await store.send(.presentation(value)) } }
        )
    }

    private var highlightSelection: Binding<String?> {
        Binding(
            get: { store.state.highlightedPlaceID },
            set: { id in Task { await store.send(.highlightPlace(id)) } }
        )
    }

    private var selectedPlace: Binding<LocalPlace?> {
        Binding(
            get: {
                guard let id = store.state.selectedPlaceID else { return nil }
                return store.state.places.value?.first { $0.id == id }
            },
            set: { place in Task { await store.send(.selectPlace(place?.id)) } }
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

private struct PlaceDetailView: View {
    let place: LocalPlace
    let location: Location

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    MockDataBanner()
                    Text(place.name).font(UtahFont.largeTitle)
                    StatusPill(title: place.category.title, symbol: place.category.symbolName, tone: .info)
                    Text(place.address)
                    Text(distance)
                    Text(place.description)
                    Text(place.category == .hospitals ? SampleCopy.hospitalDisclaimer : SampleCopy.placeDisclaimer)
                        .font(UtahFont.callout)
                        .foregroundStyle(UtahColor.secondaryText)
                }
                .padding(Spacing.large)
            }
            .navigationTitle("Place")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var distance: String {
        let miles = DistanceCalculator.miles(
            fromLatitude: location.latitude,
            fromLongitude: location.longitude,
            toLatitude: place.latitude,
            toLongitude: place.longitude
        )
        return "\(DistanceCalculator.label(miles: miles)) from the sample city center"
    }
}

#Preview("List") {
    NavigationStack { ExploreView(store: .preview(populated), onSelectLocation: { _ in }) }
}

#Preview("Map") {
    NavigationStack { ExploreView(store: .preview(mapState), onSelectLocation: { _ in }) }
}

private var populated: ExploreState {
    ExploreReducer.reduce(
        ExploreState(selectedLocation: PreviewCatalog.saltLakeCity, locations: [PreviewCatalog.saltLakeCity]),
        .loaded([PreviewCatalog.park, PreviewCatalog.library, PreviewCatalog.hospital])
    )
}

private var mapState: ExploreState {
    var state = populated
    state.presentation = .map
    return state
}
