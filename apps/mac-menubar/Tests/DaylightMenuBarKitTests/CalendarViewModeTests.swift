// XCTest coverage for calendar navigation periods.
// Exports: CalendarViewModeTests
// Deps: XCTest, DaylightMenuBarKit

import XCTest
@testable import DaylightMenuBarKit

final class CalendarViewModeTests: XCTestCase {
    func testPeriodTitlesMatchViewMode() {
        let date = LocalDate(year: 2026, month: 6, day: 29)

        XCTAssertEqual(CalendarPeriod.period(for: date, mode: .month).title, "2026.06")
        XCTAssertEqual(CalendarPeriod.period(for: date, mode: .year).title, "2026")
        XCTAssertEqual(CalendarPeriod.period(for: date, mode: .decade).title, "2020-2029")
        XCTAssertEqual(CalendarPeriod.period(for: date, mode: .century).title, "2000-2099")
    }

    func testPeriodTitlesUseBuddhistEraInThai() {
        let saved = Loc.language
        defer { Loc.language = saved }
        Loc.language = .th
        let date = LocalDate(year: 2026, month: 6, day: 29)

        XCTAssertEqual(CalendarPeriod.period(for: date, mode: .month).title, "2569.06")
        XCTAssertEqual(CalendarPeriod.period(for: date, mode: .year).title, "2569")
        XCTAssertEqual(CalendarPeriod.period(for: date, mode: .decade).title, "2563-2572")
        XCTAssertEqual(CalendarPeriod.period(for: date, mode: .century).title, "2543-2642")
    }

    func testPeriodNavigationStepMatchesViewMode() {
        XCTAssertEqual(CalendarPeriod.period(for: sampleDate(), mode: .month).nextStepMonths, 1)
        XCTAssertEqual(CalendarPeriod.period(for: sampleDate(), mode: .year).nextStepMonths, 12)
        XCTAssertEqual(CalendarPeriod.period(for: sampleDate(), mode: .decade).nextStepMonths, 120)
        XCTAssertEqual(CalendarPeriod.period(for: sampleDate(), mode: .century).nextStepMonths, 1_200)
    }

    private func sampleDate() -> LocalDate {
        LocalDate(year: 2026, month: 6, day: 29)
    }
}
