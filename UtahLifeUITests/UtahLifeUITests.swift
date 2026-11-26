import XCTest

final class UtahLifeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchAndAllTabs() {
        let app = launched()
        XCTAssertTrue(app.staticTexts["Sample data. Not a live observation."].waitForExistence(timeout: 8))
        for tab in ["Explore", "Travel", "Environment", "Alerts", "Home"] {
            tapTab(tab, in: app)
            XCTAssertTrue(app.navigationBars[tab].waitForExistence(timeout: 4))
        }
    }

    func testHomeCardsOpenFeaturesAndLocationChanges() {
        let app = launched()
        app.buttons["home.weatherCard"].tap()
        XCTAssertTrue(app.navigationBars["Environment"].waitForExistence(timeout: 4))
        tapTab("Home", in: app)
        app.buttons["home.trafficCard"].tap()
        XCTAssertTrue(app.navigationBars["Travel"].waitForExistence(timeout: 4))
        tapTab("Home", in: app)
        app.buttons["home.locationButton"].tap()
        app.buttons["location.row.west-jordan"].tap()
        XCTAssertTrue(app.staticTexts["West Jordan, UT"].waitForExistence(timeout: 4))
    }

    func testExploreSearchAndFilter() {
        let app = launched()
        tapTab("Explore", in: app)
        let search = app.textFields["explore.search"]
        XCTAssertTrue(search.waitForExistence(timeout: 6))
        search.tap()
        search.typeText("Library")
        XCTAssertTrue(app.staticTexts["Salt Lake City Public Library"].waitForExistence(timeout: 4))
        XCTAssertFalse(app.staticTexts["Liberty Park"].exists)
        app.buttons["explore.clear"].tap()
        app.buttons["explore.chip.parks"].tap()
        XCTAssertTrue(app.staticTexts["Liberty Park"].waitForExistence(timeout: 4))
    }

    func testTravelSeverityFilter() {
        let app = launched()
        tapTab("Travel", in: app)
        XCTAssertTrue(app.buttons["travel.severity.critical"].waitForExistence(timeout: 6))
        app.buttons["travel.severity.critical"].tap()
        XCTAssertTrue(app.staticTexts["Parleys sample closure"].waitForExistence(timeout: 4))
        XCTAssertFalse(app.staticTexts["I-15 sample slowdown"].exists)
    }

    func testEnvironmentForecastAndExplanation() {
        let app = launched()
        tapTab("Environment", in: app)
        let forecast = app.buttons["environment.forecast.slc-day-1"]
        XCTAssertTrue(forecast.waitForExistence(timeout: 6))
        forecast.tap()
        XCTAssertTrue(app.staticTexts["Selected sample day"].waitForExistence(timeout: 4))
        app.buttons["environment.aqiDisclosure"].tap()
        XCTAssertTrue(app.staticTexts["environment.aqiExplanation"].waitForExistence(timeout: 4) || app.otherElements["environment.aqiExplanation"].waitForExistence(timeout: 2))
    }

    func testAlertCanBeMarkedRead() {
        let app = launched()
        tapTab("Alerts", in: app)
        let row = app.buttons["alerts.row.slc-alert-snow"]
        XCTAssertTrue(row.waitForExistence(timeout: 6))
        row.tap()
        app.buttons["alerts.markRead"].tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 4))
        XCTAssertTrue(row.staticTexts["Read"].exists)
    }

    func testEmptyAndFailureScenarios() {
        let empty = XCUIApplication()
        empty.launchArguments = ["-UtahLifeScenario", "empty", "-UtahLifeResetPreferences"]
        empty.launch()
        XCTAssertTrue(empty.staticTexts["No sample data"].waitForExistence(timeout: 8))

        let failed = XCUIApplication()
        failed.launchArguments = ["-UtahLifeScenario", "failure", "-UtahLifeResetPreferences"]
        failed.launch()
        XCTAssertTrue(failed.buttons["Try Again"].waitForExistence(timeout: 8))
    }

    private func launched() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UtahLifeScenario", "populated", "-UtahLifeResetPreferences"]
        app.launch()
        return app
    }

    /// Standard iPhones expose tabs as a tab bar. iPhone Duo places the same tabs in a trailing rail that is not a `TabBar`.
    /// Rail buttons use the SF Symbol name (`map`, `cloud.sun`) rather than an empty identifier.
    private func tapTab(_ name: String, in app: XCUIApplication) {
        let tabBarButton = app.tabBars.buttons[name]
        if tabBarButton.exists {
            tabBarButton.tap()
            return
        }

        let deadline = Date().addingTimeInterval(6)
        let candidates = app.buttons.matching(NSPredicate(format: "label == %@", name))
        while Date() < deadline {
            for index in 0..<candidates.count {
                let button = candidates.element(boundBy: index)
                guard button.exists, isTabRailButton(button), button.isHittable else { continue }
                button.tap()
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        XCTFail("Missing tab \(name)")
    }

    private func isTabRailButton(_ button: XCUIElement) -> Bool {
        let identifier = button.identifier
        let contentPrefixes = ["home.", "explore.", "travel.", "environment.", "alerts.", "location.", "state.", "screen."]
        return !contentPrefixes.contains { identifier.hasPrefix($0) }
    }
}
