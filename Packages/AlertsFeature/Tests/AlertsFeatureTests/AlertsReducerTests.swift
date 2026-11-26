import CoreKit
import DomainKit
import XCTest
@testable import AlertsFeature

final class AlertsReducerTests: XCTestCase {
    func testFiltersComposeAndUnreadComesFirst() {
        let loaded = AlertsReducer.reduce(base, .loaded([PreviewCatalog.readAlert, PreviewCatalog.unreadAlert]))
        XCTAssertEqual(loaded.visibleAlerts.map(\.id), [PreviewCatalog.unreadAlert.id, PreviewCatalog.readAlert.id])
        let snow = AlertsReducer.reduce(loaded, .filters([.snow], []))
        XCTAssertEqual(snow.visibleAlerts.map(\.id), [PreviewCatalog.unreadAlert.id])
        let info = AlertsReducer.reduce(loaded, .filters([.snow], [.info]))
        XCTAssertTrue(info.visibleAlerts.isEmpty)
    }

    func testReadStateAndPendingSelection() {
        var read = PreviewCatalog.unreadAlert
        read.isRead = true
        let updated = AlertsReducer.reduce(
            AlertsReducer.reduce(base, .loaded([PreviewCatalog.unreadAlert])),
            .loaded([read])
        )
        XCTAssertEqual(updated.visibleAlerts.first?.isRead, true)

        let pending = AlertsReducer.reduce(base, .pending(PreviewCatalog.unreadAlert.id))
        let opened = AlertsReducer.reduce(pending, .loaded([PreviewCatalog.unreadAlert, PreviewCatalog.readAlert]))
        XCTAssertEqual(opened.selectedAlertID, PreviewCatalog.unreadAlert.id)
        XCTAssertNil(opened.pendingAlertID)
    }

    func testPreferencesStayLocalFlags() {
        var preferences = NotificationPreferences.sampleDefault
        preferences.masterEnabled = true
        let state = AlertsReducer.reduce(base, .preferences(preferences, presented: true))
        XCTAssertTrue(state.preferences.masterEnabled)
        XCTAssertTrue(state.isPreferencesPresented)
        XCTAssertFalse(NotificationPreferences.sampleDefault.masterEnabled)
    }

    func testEmptyAndFailure() {
        XCTAssertEqual(AlertsReducer.reduce(base, .loaded([])).alerts, .empty)
        XCTAssertEqual(AlertsReducer.reduce(base, .failed(.unavailable("Sample alerts could not be loaded."))).alerts.error?.isEmpty, false)
    }

    @MainActor
    func testStoreMarksOneAlertRead() async {
        let repository = MutableAlertsRepository()
        let store = AlertsStore(
            location: PreviewCatalog.saltLakeCity,
            locations: [PreviewCatalog.saltLakeCity],
            loader: LoadAlertsUseCase(repository: repository),
            markRead: MarkAlertAsReadUseCase(repository: repository),
            markAll: MarkAllAlertsAsReadUseCase(repository: repository),
            preferences: NotificationPreferencesUseCase(repository: MemoryNotificationPreferences()),
            selectLocation: SelectLocationUseCase(preferences: MemoryLocationPreferences())
        )
        await store.send(.onAppear)
        XCTAssertEqual(store.state.visibleAlerts.first?.isRead, false)
        await store.send(.markRead(PreviewCatalog.unreadAlert.id))
        let updated = store.state.alerts.value?.first { $0.id == PreviewCatalog.unreadAlert.id }
        XCTAssertEqual(updated?.isRead, true)
        await store.send(.markAllRead)
        XCTAssertEqual(store.state.alerts.value?.allSatisfy(\.isRead), true)
    }

    private var base: AlertsState {
        AlertsState(selectedLocation: PreviewCatalog.saltLakeCity, locations: [PreviewCatalog.saltLakeCity])
    }
}

private actor MutableAlertsRepository: AlertsRepositoryProtocol {
    private var alerts = [PreviewCatalog.unreadAlert, PreviewCatalog.readAlert]

    func alerts(for location: Location) async throws -> [LocalAlert] { alerts }

    func markAsRead(id: String) async throws {
        alerts = alerts.map { alert in
            guard alert.id == id else { return alert }
            var copy = alert
            copy.isRead = true
            return copy
        }
    }

    func markAllAsRead() async throws {
        alerts = alerts.map { alert in
            var copy = alert
            copy.isRead = true
            return copy
        }
    }
}
