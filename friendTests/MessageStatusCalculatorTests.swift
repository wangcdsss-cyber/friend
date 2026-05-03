import XCTest
@testable import friend

final class MessageStatusCalculatorTests: XCTestCase {
    func testIncomingMessageHasNoStatus() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let status = MessageStatusCalculator.status(
            currentUid: "me",
            messageSenderId: "other",
            messageTime: now,
            otherUid: "other",
            otherReadAt: now,
            isSending: false,
            isFailed: false
        )
        XCTAssertNil(status)
    }

    func testSending() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let status = MessageStatusCalculator.status(
            currentUid: "me",
            messageSenderId: "me",
            messageTime: now,
            otherUid: "other",
            otherReadAt: nil,
            isSending: true,
            isFailed: false
        )
        XCTAssertEqual(status, .sending)
    }

    func testFailed() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let status = MessageStatusCalculator.status(
            currentUid: "me",
            messageSenderId: "me",
            messageTime: now,
            otherUid: "other",
            otherReadAt: nil,
            isSending: false,
            isFailed: true
        )
        XCTAssertEqual(status, .failed)
    }

    func testRead() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let messageTime = now.addingTimeInterval(-10)
        let status = MessageStatusCalculator.status(
            currentUid: "me",
            messageSenderId: "me",
            messageTime: messageTime,
            otherUid: "other",
            otherReadAt: now,
            isSending: false,
            isFailed: false
        )
        XCTAssertEqual(status, .read)
    }

    func testSentWhenNotReadYet() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let messageTime = now
        let status = MessageStatusCalculator.status(
            currentUid: "me",
            messageSenderId: "me",
            messageTime: messageTime,
            otherUid: "other",
            otherReadAt: now.addingTimeInterval(-1),
            isSending: false,
            isFailed: false
        )
        XCTAssertEqual(status, .sent)
    }
}

