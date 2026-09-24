// XCTest coverage for native calendar grid generation.
// Exports: CalendarModelTests
// Deps: XCTest, DaylightMenuBarKit

import XCTest
@testable import DaylightMenuBarKit

final class CalendarModelTests: XCTestCase {
    func testMonthGridAlwaysReturnsSixWeeksStartingOnMonday() {
        let model = CalendarModel()
        let today = LocalDate(year: 2026, month: 6, day: 29)

        let days = model.monthGrid(year: 2026, month: 6, today: today)

        XCTAssertEqual(days.count, 42)
        XCTAssertEqual(days.first?.date, LocalDate(year: 2026, month: 6, day: 1))
        XCTAssertEqual(days.last?.date, LocalDate(year: 2026, month: 7, day: 12))
        XCTAssertEqual(days.filter(\.isToday).map(\.date), [today])
    }

    func testMonthGridIncludesPreviousMonthPadding() {
        let model = CalendarModel()

        let days = model.monthGrid(
            year: 2026,
            month: 8,
            today: LocalDate(year: 2026, month: 8, day: 1)
        )

        XCTAssertEqual(days.first?.date, LocalDate(year: 2026, month: 7, day: 27))
        XCTAssertTrue(days.prefix(5).allSatisfy(\.isOutsideMonth))
    }

    func testMonthGridUsesSelectedWeekRuleStartDay() {
        let model = CalendarModel()
        let today = LocalDate(year: 2026, month: 8, day: 1)

        let us = model.monthGrid(year: 2026, month: 8, today: today, weekRule: .us)
        let arabic = model.monthGrid(year: 2026, month: 8, today: today, weekRule: .arabic)
        let hebrew = model.monthGrid(year: 2026, month: 8, today: today, weekRule: .hebrew)

        XCTAssertEqual(us.first?.date, LocalDate(year: 2026, month: 7, day: 26))
        XCTAssertEqual(arabic.first?.date, LocalDate(year: 2026, month: 8, day: 1))
        XCTAssertEqual(hebrew.first?.date, LocalDate(year: 2026, month: 7, day: 26))
    }

    func testWeekNumbersFollowSelectedWeekRule() {
        let model = CalendarModel()
        let date = LocalDate(year: 2021, month: 1, day: 1)

        XCTAssertEqual(model.weekNumber(for: date, weekRule: .iso8601), 53)
        XCTAssertEqual(model.weekNumber(for: date, weekRule: .us), 1)
    }

    func testWeekdayLabelsFollowSelectedWeekRuleAndLanguage() {
        let saved = Loc.language
        defer { Loc.language = saved }

        Loc.language = .en
        XCTAssertEqual(CalendarWeekRule.iso8601.weekdayLabels.first, "Mon")
        XCTAssertEqual(CalendarWeekRule.us.weekdayLabels.first, "Sun")
        XCTAssertEqual(CalendarWeekRule.arabic.weekdayLabels.first, "Sat")
        XCTAssertEqual(CalendarWeekRule.hebrew.weekdayLabels.first, "Sun")

        Loc.language = .zh
        XCTAssertEqual(CalendarWeekRule.iso8601.weekdayLabels, ["一", "二", "三", "四", "五", "六", "日"])
        XCTAssertEqual(CalendarWeekRule.us.weekdayLabels.first, "日")

        // Weekend columns key off weekday indices, not label text.
        XCTAssertEqual(CalendarWeekRule.iso8601.weekdayIndices, [1, 2, 3, 4, 5, 6, 0])
        XCTAssertEqual(CalendarWeekRule.arabic.weekdayIndices.first, 6)
    }
}
