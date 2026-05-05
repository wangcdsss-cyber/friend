import XCTest
@testable import friend

final class BirthdayValidatorTests: XCTestCase {
    func testAgeCalculation() {
        let cal = Calendar(identifier: .gregorian)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let birthday = cal.date(from: DateComponents(year: 1990, month: 1, day: 1))!
        XCTAssertTrue(BirthdayValidator.age(on: now, birthday: birthday, calendar: cal) >= 30)
    }

    func testAllowedAgeRange() {
        let cal = Calendar(identifier: .gregorian)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let ok = cal.date(from: DateComponents(year: 1995, month: 1, day: 1))!
        XCTAssertTrue(BirthdayValidator.isAllowedAge(birthday: ok, now: now, calendar: cal, min: 18, max: 80))
    }
}

