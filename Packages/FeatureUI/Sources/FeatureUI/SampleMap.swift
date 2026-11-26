import MapKit
import SwiftUI

public struct SamplePoint: Identifiable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var latitude: Double
    public var longitude: Double
    public var symbol: String

    public init(id: String, title: String, latitude: Double, longitude: Double, symbol: String) {
        self.id = id
        self.title = title
        self.latitude = latitude
        self.longitude = longitude
        self.symbol = symbol
    }
}

public struct SampleMap: View {
    @Binding private var selection: String?
    private let points: [SamplePoint]
    private let centerLatitude: Double
    private let centerLongitude: Double
    private let identifier: String
    @State private var position: MapCameraPosition = .automatic

    public init(
        points: [SamplePoint],
        centerLatitude: Double,
        centerLongitude: Double,
        selection: Binding<String?>,
        identifier: String
    ) {
        self.points = points
        self.centerLatitude = centerLatitude
        self.centerLongitude = centerLongitude
        self._selection = selection
        self.identifier = identifier
    }

    public var body: some View {
        Map(position: $position, selection: $selection) {
            ForEach(points) { point in
                Marker(point.title, systemImage: point.symbol, coordinate: CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude))
                    .tag(point.id)
            }
        }
        .mapStyle(.standard)
        .accessibilityIdentifier(identifier)
        .accessibilityLabel("Sample map")
        .onAppear(perform: recenter)
        .onChange(of: centerLatitude) { _, _ in recenter() }
        .onChange(of: centerLongitude) { _, _ in recenter() }
    }

    private func recenter() {
        position = .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude),
                span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
            )
        )
    }
}
