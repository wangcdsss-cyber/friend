import XCTest

final class ChatE2ETests: XCTestCase {
    func testChatListPullToRefreshAndEnterRoomAndSendText() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui_testing", "1"]
        app.launch()

        let tab = app.tabBars.buttons["メッセージ"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10))
        tab.tap()

        let list = app.tables["chatList"]
        XCTAssertTrue(list.waitForExistence(timeout: 10))

        list.swipeDown()

        let firstCell = list.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 10))
        firstCell.tap()

        let input = app.textFields["messageInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        input.tap()

        let message = "e2e-\(Int(Date().timeIntervalSince1970))"
        input.typeText(message)

        let sendButton = app.buttons["sendButton"]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 5))
        sendButton.tap()

        XCTAssertTrue(app.staticTexts[message].waitForExistence(timeout: 10))
    }

    func testOpenImagePickerActionSheet() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui_testing", "1"]
        app.launch()

        let tab = app.tabBars.buttons["メッセージ"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10))
        tab.tap()

        let list = app.tables["chatList"]
        XCTAssertTrue(list.waitForExistence(timeout: 10))

        let firstCell = list.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 10))
        firstCell.tap()

        let mediaButton = app.buttons["mediaButton"]
        XCTAssertTrue(mediaButton.waitForExistence(timeout: 10))
        mediaButton.tap()

        XCTAssertTrue(app.buttons["拍照"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["从相册选择"].waitForExistence(timeout: 5))
    }

    func testSendTestImageShowsImageBubble() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui_testing", "1"]
        app.launch()

        let tab = app.tabBars.buttons["メッセージ"]
        XCTAssertTrue(tab.waitForExistence(timeout: 10))
        tab.tap()

        let list = app.tables["chatList"]
        XCTAssertTrue(list.waitForExistence(timeout: 10))

        let firstCell = list.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 10))
        firstCell.tap()

        let mediaButton = app.buttons["mediaButton"]
        XCTAssertTrue(mediaButton.waitForExistence(timeout: 10))
        mediaButton.tap()

        let sendTestImage = app.buttons["发送测试图片"]
        XCTAssertTrue(sendTestImage.waitForExistence(timeout: 5))
        sendTestImage.tap()

        let predicate = NSPredicate(format: "identifier BEGINSWITH %@", "imageBubble_")
        let anyImageBubble = app.otherElements.matching(predicate).firstMatch
        XCTAssertTrue(anyImageBubble.waitForExistence(timeout: 10))
    }
}
