import XCTest

final class FoodLoggingUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-skipOnboarding", "-skipAuth"]
        app.launch()
    }

    func testDashboardTabExists() {
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        XCTAssertTrue(dashboardTab.waitForExistence(timeout: 5))
        dashboardTab.tap()
    }

    func testScanTabExists() {
        let scanTab = app.tabBars.buttons["Scan"]
        XCTAssertTrue(scanTab.waitForExistence(timeout: 5))
        scanTab.tap()
    }

    func testCoachTabExists() {
        let coachTab = app.tabBars.buttons["AI Coach"]
        XCTAssertTrue(coachTab.waitForExistence(timeout: 5))
        coachTab.tap()
    }

    func testProfileTabShowsSettings() {
        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5))
        profileTab.tap()

        // Settings gear should be visible
        let settingsButton = app.navigationBars.buttons.matching(NSPredicate(format: "label CONTAINS 'gear' OR label CONTAINS 'Settings'")).firstMatch
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 3))
    }

    func testNavigateBetweenAllTabs() {
        let tabs = ["Dashboard", "Scan", "AI Coach", "Pair Scale", "Profile"]
        for tab in tabs {
            let tabButton = app.tabBars.buttons[tab]
            XCTAssertTrue(tabButton.waitForExistence(timeout: 3), "Tab '\(tab)' should exist")
            tabButton.tap()
        }
    }
}
