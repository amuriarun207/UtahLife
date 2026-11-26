import CoreKit
import DomainKit
import FeatureUI
import XCTest
@testable import EnvironmentFeature

final class EnvironmentReducerTests: XCTestCase {
    func testLoadedSelectsFirstDayAndDerivesContent() {
        let snapshot = EnvironmentSnapshot(
            weather: PreviewCatalog.weather,
            hourly: PreviewCatalog.hourly,
            daily: PreviewCatalog.daily,
            airQuality: PreviewCatalog.airQuality
        )
        let state = EnvironmentReducer.reduce(base, .loaded(snapshot))
        XCTAssertEqual(state.selectedDayID, PreviewCatalog.daily.first?.id)
        XCTAssertEqual(state.snapshot.value?.airQuality.category, .moderate)
    }

    func testFocusAndExplanationAreIndependentOfWeather() {
        let focused = EnvironmentReducer.reduce(base, .section(.airQuality))
        XCTAssertEqual(focused.section, .airQuality)
        let expanded = EnvironmentReducer.reduce(focused, .aqiExpanded(true))
        XCTAssertTrue(expanded.isAQIExpanded)
        XCTAssertEqual(expanded.snapshot, .idle)
    }

    func testRefreshKeepsSnapshot() {
        let snapshot = EnvironmentSnapshot(
            weather: PreviewCatalog.weather,
            hourly: PreviewCatalog.hourly,
            daily: PreviewCatalog.daily,
            airQuality: PreviewCatalog.airQuality
        )
        let loaded = EnvironmentReducer.reduce(base, .loaded(snapshot))
        let refreshing = EnvironmentReducer.reduce(loaded, .refreshStarted)
        XCTAssertTrue(refreshing.isRefreshing)
        XCTAssertEqual(refreshing.snapshot, loaded.snapshot)
    }

    func testFailureAndEmpty() {
        XCTAssertEqual(EnvironmentReducer.reduce(base, .failed(.message("sample"))).snapshot, .failed(.message("sample")))
        XCTAssertEqual(EnvironmentReducer.reduce(base, .empty).snapshot, .empty)
    }

    @MainActor
    func testStoreLoadsForecast() async {
        let store = EnvironmentStore(
            location: PreviewCatalog.saltLakeCity,
            locations: [PreviewCatalog.saltLakeCity],
            loader: PreviewSupport.environment(),
            selectLocation: PreviewSupport.selectLocation()
        )
        await store.send(.focus(.airQuality))
        await store.send(.onAppear)
        XCTAssertEqual(store.state.section, .airQuality)
        XCTAssertEqual(store.state.snapshot.value?.daily.count, 7)
        await store.send(.selectDay(PreviewCatalog.daily[1].id))
        XCTAssertEqual(store.state.selectedDayID, PreviewCatalog.daily[1].id)
    }

    private var base: EnvironmentState {
        EnvironmentState(selectedLocation: PreviewCatalog.saltLakeCity, locations: [PreviewCatalog.saltLakeCity])
    }
}
