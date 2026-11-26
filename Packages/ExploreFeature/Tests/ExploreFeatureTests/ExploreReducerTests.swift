import CoreKit
import DomainKit
import FeatureUI
import XCTest
@testable import ExploreFeature

final class ExploreReducerTests: XCTestCase {
    func testSearchAndCategoryStayInState() {
        let loaded = ExploreReducer.reduce(
            base,
            .loaded([PreviewCatalog.park, PreviewCatalog.library, PreviewCatalog.hospital])
        )
        let libraries = ExploreReducer.reduce(loaded, .query("library", nil))
        XCTAssertEqual(libraries.visiblePlaces.map(\.id), [PreviewCatalog.library.id])
        let parks = ExploreReducer.reduce(loaded, .query("", .parks))
        XCTAssertEqual(parks.visiblePlaces.map(\.category), [.parks])
        let cleared = ExploreReducer.reduce(parks, .query("", nil))
        XCTAssertEqual(cleared.visiblePlaces.count, 3)
    }

    func testEmptyAndFailure() {
        XCTAssertEqual(ExploreReducer.reduce(base, .loaded([])).places, .empty)
        XCTAssertEqual(ExploreReducer.reduce(base, .failed(.unavailable("Sample places could not be loaded."))).places.error?.message, "Sample places could not be loaded.")
    }

    @MainActor
    func testStoreSearchDoesNotRequireLocationPermission() async {
        let store = ExploreStore(
            location: PreviewCatalog.saltLakeCity,
            locations: [PreviewCatalog.saltLakeCity],
            search: PreviewSupport.places(),
            selectLocation: PreviewSupport.selectLocation()
        )
        await store.send(.onAppear)
        await store.send(.queryChanged("Clinic"))
        XCTAssertEqual(store.state.visiblePlaces.map(\.id), [PreviewCatalog.hospital.id])
        await store.send(.clearFilters)
        XCTAssertEqual(store.state.visiblePlaces.count, 3)
    }

    private var base: ExploreState {
        ExploreState(selectedLocation: PreviewCatalog.saltLakeCity, locations: [PreviewCatalog.saltLakeCity])
    }
}
