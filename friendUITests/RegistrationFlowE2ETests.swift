import XCTest

final class RegistrationFlowE2ETests: XCTestCase {
    func testRegistrationEntryShowsMethodSelection() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui_testing_force_logout", "1"]
        app.launch()

        let signup = app.buttons["authEntry_signup"]
        XCTAssertTrue(signup.waitForExistence(timeout: 10))
        signup.tap()

        XCTAssertTrue(app.buttons["regMethod_email"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["regMethod_phone"].waitForExistence(timeout: 5))
    }
}

