// XCTest coverage for menu bar status segment resolution.
// Exports: StatusTitleProviderTests
// Deps: XCTest, DaylightMenuBarKit, Foundation Calendar

import Foundation
import XCTest
@testable import DaylightMenuBarKit

final class StatusTitleProviderTests: XCTestCase {
    func testSegmentsFollowConfiguredOrder() {
        let previous = Loc.language
        defer { Loc.language = previous }
        Loc.language = .zh
        let provider = StatusTitleProvider(calendar: testCalendar())
        var settings = UserSettings()
        settings.statusSegments = ["weekday", "time"]

        let segments = provider.segments(
            today: LocalDate(year: 2026, month: 7, day: 2),
            settings: settings,
            now: date(year: 2026, month: 7, day: 2, hour: 14, minute: 32)
        )

        XCTAssertEqual(segments, [.text("周四"), .text("14:32")])
    }

    func testMoonAndDateBoxSegments() {
        let provider = StatusTitleProvider(calendar: testCalendar())
        var settings = UserSettings()
        settings.statusSegments = ["moon", "dateBox"]

        let segments = provider.segments(today: LocalDate(year: 2026, month: 7, day: 2), settings: settings)

        XCTAssertEqual(segments.count, 2)
        if case .moon = segments[0] {} else { XCTFail("expected moon segment") }
        XCTAssertEqual(segments[1], .dateBox("2"))
    }

    func testLunarSegmentUsesDayName() {
        let provider = StatusTitleProvider(calendar: testCalendar())
        var settings = UserSettings()
        settings.statusSegments = ["lunar"]

        let segments = provider.segments(today: LocalDate(year: 2026, month: 7, day: 2), settings: settings)

        XCTAssertEqual(segments, [.text("十八")])
    }

    func testTwelveHourFormat() {
        let provider = StatusTitleProvider(calendar: testCalendar())
        var settings = UserSettings()
        settings.statusSegments = ["time"]
        settings.statusUse24HourTime = false

        let segments = provider.segments(
            today: LocalDate(year: 2026, month: 7, day: 2),
            settings: settings,
            now: date(year: 2026, month: 7, day: 2, hour: 14, minute: 32)
        )

        XCTAssertEqual(segments, [.text("2:32 PM")])
    }

    func testEmptyConfigurationProducesNoSegments() {
        let provider = StatusTitleProvider(calendar: testCalendar())
        var settings = UserSettings()
        settings.statusSegments = []

        XCTAssertTrue(provider.segments(today: LocalDate(year: 2026, month: 7, day: 2), settings: settings).isEmpty)
    }

    private func testCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        testCalendar().date(from: DateComponents(
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        ))!
    }
}
