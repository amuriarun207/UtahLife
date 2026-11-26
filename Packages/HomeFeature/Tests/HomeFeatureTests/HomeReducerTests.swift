import CoreKit
import DomainKit
import FeatureUI
import XCTest
@testable import HomeFeature

final class HomeReducerTests: XCTestCase {
    func testLoadStartedReplacesContentWithLoading() {
        let loaded = HomeReducer.reduce(base, .dashboardLoaded(PreviewCatalog.dashboard()))
        let loading = HomeReducer.reduce(loaded, .loadStarted)
        XCTAssertEqual(loading.weather, .loading)
        XCTAssertEqual(loading.alerts, .loading)
        XCTAssertFalse(loading.isRefreshing)
    }

    func testRefreshKeepsLoadedContent() {
        let loaded = HomeReducer.reduce(base, .dashboardLoaded(PreviewCatalog.dashboard()))
        let refreshing = HomeReducer.reduce(loaded, .refreshStarted)
        XCTAssertTrue(refreshing.isRefreshing)
        XCTAssertEqual(refreshing.weather, loaded.weather)
    }

    func testLoadedDashboardSplitsEmptyHourlyAndAlerts() {
        var data = PreviewCatalog.dashboard()
        data.hourly = []
        data.alerts = []
        let state = HomeReducer.reduce(base, .dashboardLoaded(data))
        XCTAssertEqual(state.greeting, "Good morning")
        XCTAssertEqual(state.hourly, .empty)
        XCTAssertEqual(state.alerts, .empty)
        XCTAssertEqual(state.weather.value?.locationId, "slc")
    }

    func testFailureAndEmptyAndNavigation() {
        let failed = HomeReducer.reduce(base, .dashboardFailed(.message("offline sample")))
        XCTAssertEqual(failed.weather, .failed(.message("offline sample")))
        let empty = HomeReducer.reduce(failed, .dashboardEmpty)
        XCTAssertEqual(empty.airQuality, .empty)
        let navigated = HomeReducer.reduce(empty, .requestNavigation(.environment(.airQuality)))
        XCTAssertEqual(navigated.navigation, .environment(.airQuality))
        XCTAssertNil(HomeReducer.reduce(navigated, .clearNavigation).navigation)
    }

    func testLocationSelectionDismissesPicker() {
        let presented = HomeReducer.reduce(base, .presentLocationPicker(true))
        let changed = HomeReducer.reduce(presented, .locationChanged(PreviewCatalog.westJordan))
        XCTAssertEqual(changed.selectedLocation.id, "west-jordan")
        XCTAssertFalse(changed.isLocationPickerPresented)
    }

    @MainActor
    func testStoreLoadsDashboard() async {
        let store = HomeStore(
            location: PreviewCatalog.saltLakeCity,
            locations: [PreviewCatalog.saltLakeCity],
            dashboard: PreviewSupport.homeDashboard(),
            selectLocation: PreviewSupport.selectLocation()
        )
        await store.send(.onAppear)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = PreviewCatalog.saltLakeCity.timeZone
        let expected = DayPartGreeting.text(for: PreviewCatalog.observedAt, calendar: calendar)
        XCTAssertEqual(store.state.greeting, expected)
        XCTAssertEqual(store.state.weather.value?.temperature.display, "31°F")
        await store.send(.onAppear)
        XCTAssertEqual(store.state.greeting, expected)
    }

    private var base: HomeState {
        HomeState(
            selectedLocation: PreviewCatalog.saltLakeCity,
            locations: [PreviewCatalog.saltLakeCity, PreviewCatalog.westJordan]
        )
    }
}
