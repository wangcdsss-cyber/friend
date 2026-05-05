import XCTest

final class AuthFlowE2ETests: XCTestCase {
    func testAuthEntryToLoginMethodSelection() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui_testing_force_logout", "1"]
        app.launch()

        let login = app.buttons["authEntry_login"]
        XCTAssertTrue(login.waitForExistence(timeout: 10))
        login.tap()

        XCTAssertTrue(app.buttons["loginMethod_email"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["loginMethod_phone"].waitForExistence(timeout: 5))
    }

    func testNavigateToEmailLoginAndForgotPassword() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui_testing_force_logout", "1"]
        app.launch()

        app.buttons["authEntry_login"].tap()
        app.buttons["loginMethod_email"].tap()

        let email = app.textFields["emailLogin_email"]
        XCTAssertTrue(email.waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["emailLogin_password"].waitForExistence(timeout: 5))

        app.buttons["emailLogin_forgot"].tap()
        XCTAssertTrue(app.staticTexts["パスワード再設定"].waitForExistence(timeout: 5))
    }

    func testNavigateToPhoneLogin() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui_testing_force_logout", "1"]
        app.launch()

        app.buttons["authEntry_login"].tap()
        app.buttons["loginMethod_phone"].tap()

        XCTAssertTrue(app.textFields["phoneLogin_phone"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["phoneLogin_sendCode"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["phoneLogin_code"].waitForExistence(timeout: 5))
    }
}

