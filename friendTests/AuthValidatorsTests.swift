import XCTest
@testable import friend

final class AuthValidatorsTests: XCTestCase {
    func testEmailValidation() {
        XCTAssertTrue(AuthValidators.isValidEmail("a@b.co"))
        XCTAssertTrue(AuthValidators.isValidEmail("user.name+tag@example.co.jp"))
        XCTAssertFalse(AuthValidators.isValidEmail("not-an-email"))
        XCTAssertFalse(AuthValidators.isValidEmail("a@b"))
    }

    func testNormalizeJapaneseE164FromNational() {
        XCTAssertEqual(AuthValidators.normalizedJapaneseE164(from: "09012345678"), "+819012345678")
        XCTAssertEqual(AuthValidators.normalizedJapaneseE164(from: "080-1111-2222"), "+818011112222")
        XCTAssertNil(AuthValidators.normalizedJapaneseE164(from: "0312345678"))
        XCTAssertNil(AuthValidators.normalizedJapaneseE164(from: "0901234567"))
    }

    func testNormalizeJapaneseE164FromPlus81() {
        XCTAssertEqual(AuthValidators.normalizedJapaneseE164(from: "+81 90 1234 5678"), "+819012345678")
        XCTAssertNil(AuthValidators.normalizedJapaneseE164(from: "+81901234567"))
    }
}

