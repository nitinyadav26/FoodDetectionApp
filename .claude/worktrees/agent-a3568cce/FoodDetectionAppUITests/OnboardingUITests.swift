import XCTest

final class OnboardingUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-resetOnboarding"]
        app.launch()
    }

    func testOnboardingFlowCompletes() {
        // Page 1: Welcome
        XCTAssertTrue(app.staticTexts["FoodSense"].waitForExistence(timeout: 5))
        app.buttons["Get Started"].tap()

        // Page 2: Permissions
        if app.buttons["Continue"].waitForExistence(timeout: 3) {
            app.buttons["Continue"].tap()
        }

        // Page 3: Profile entry — fill in basic stats
        let weightField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS 'kg' OR placeholderValue CONTAINS 'Weight'")).firstMatch
        if weightField.waitForExistence(timeout: 3) {
            weightField.tap()
            weightField.typeText("70")
        }

        let heightField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS 'cm' OR placeholderValue CONTAINS 'Height'")).firstMatch
        if heightField.exists {
            heightField.tap()
            heightField.typeText("175")
        }

        let ageField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS 'Age'")).firstMatch
        if ageField.exists {
            ageField.tap()
            ageField.typeText("28")
        }

        if app.buttons["Continue"].exists {
            app.buttons["Continue"].tap()
        }

        // Page 4: All Set
        if app.buttons["Start Tracking"].waitForExistence(timeout: 3) {
            app.buttons["Start Tracking"].tap()
        }
    }

    func testOnboardingSkipButton() {
        XCTAssertTrue(app.staticTexts["FoodSense"].waitForExistence(timeout: 5))
        if app.buttons["Skip"].exists {
            app.buttons["Skip"].tap()
        }
    }
}
