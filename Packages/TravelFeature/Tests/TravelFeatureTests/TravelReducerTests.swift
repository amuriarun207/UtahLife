import CoreKit
import DomainKit
import FeatureUI
import XCTest
@testable import TravelFeature

final class TravelReducerTests: XCTestCase {
    func testLoadedSortsCriticalFirst() {
        let state = TravelReducer.reduce(base, .loaded(overview))
        XCTAssertEqual(state.visibleIncidents.map(\.id), ["slc-closure", "slc-roadwork", "slc-slowdown"])
        XCTAssertEqual(state.overview.value?.summary.highestSeverity, .critical)
    }

    func testSeverityAndTypeFiltersCompose() {
        let loaded = TravelReducer.reduce(base, .loaded(overview))
        let critical = TravelReducer.reduce(loaded, .filters([.critical], []))
        XCTAssertEqual(critical.visibleIncidents.map(\.id), ["slc-closure"])
        let roadwork = TravelReducer.reduce(loaded, .filters([], [.roadwork]))
        XCTAssertEqual(roadwork.visibleIncidents.map(\.id), ["slc-roadwork"])
        let none = TravelReducer.reduce(loaded, .filters([.low], [.closure]))
        XCTAssertTrue(none.visibleIncidents.isEmpty)
        XCTAssertNotNil(none.overview.value)
    }

    func testEmptyOverview() {
        let empty = TravelOverview(
            incidents: [],
            roadConditions: [],
            summary: TrafficSummaryBuilder.make(incidents: [], roads: []),
            commutes: [],
            cameras: []
        )
        XCTAssertEqual(TravelReducer.reduce(base, .loaded(empty)).overview, .empty)
    }

    func testRefreshPreservesIncidents() {
        let loaded = TravelReducer.reduce(base, .loaded(overview))
        let refreshing = TravelReducer.reduce(loaded, .refreshStarted)
        XCTAssertEqual(refreshing.visibleIncidents.map(\.id), loaded.visibleIncidents.map(\.id))
        XCTAssertTrue(refreshing.isRefreshing)
    }

    @MainActor
    func testStoreAppliesSeverityFilter() async {
        let store = TravelStore(
            location: PreviewCatalog.saltLakeCity,
            locations: [PreviewCatalog.saltLakeCity],
            loader: PreviewSupport.travel(),
            selectLocation: PreviewSupport.selectLocation()
        )
        await store.send(.onAppear)
        await store.send(.toggleSeverity(.critical))
        XCTAssertEqual(store.state.visibleIncidents.map(\.severity), [.critical])
        await store.send(.clearFilters)
        XCTAssertEqual(store.state.visibleIncidents.count, 3)
    }

    private var base: TravelState {
        TravelState(selectedLocation: PreviewCatalog.saltLakeCity, locations: [PreviewCatalog.saltLakeCity])
    }

    private var overview: TravelOverview {
        TravelOverview(
            incidents: [PreviewCatalog.lowIncident, PreviewCatalog.moderateIncident, PreviewCatalog.incident],
            roadConditions: [PreviewCatalog.road],
            summary: PreviewCatalog.trafficSummary,
            commutes: [PreviewCatalog.commute],
            cameras: [PreviewCatalog.camera]
        )
    }
}
