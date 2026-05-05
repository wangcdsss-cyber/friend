import XCTest
@testable import friend

final class NicknameValidatorTests: XCTestCase {
    func testSanitizedRemovesWhitespace() {
        XCTAssertEqual(NicknameValidator.sanitized(" a b "), "ab")
        XCTAssertEqual(NicknameValidator.sanitized("a　b"), "ab")
    }

    func testLengthRules() {
        XCTAssertFalse(NicknameValidator.isValid("a"))
        XCTAssertTrue(NicknameValidator.isValid("ab"))
        XCTAssertFalse(NicknameValidator.isValid(String(repeating: "a", count: 21)))
    }
}

