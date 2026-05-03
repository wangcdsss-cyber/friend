import XCTest
@testable import friend

final class RelativeTimeFormatterTests: XCTestCase {
    func testFormatMinutes() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let date = now.addingTimeInterval(-60 * 3)
        XCTAssertEqual(RelativeTimeFormatter.format(date: date, now: now), "3分前")
    }

    func testFormatHours() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let date = now.addingTimeInterval(-60 * 60 * 2)
        XCTAssertEqual(RelativeTimeFormatter.format(date: date, now: now), "2時間前")
    }

    func testFormatDays() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let date = now.addingTimeInterval(-60 * 60 * 24 * 5)
        XCTAssertEqual(RelativeTimeFormatter.format(date: date, now: now), "5日前")
    }
}

