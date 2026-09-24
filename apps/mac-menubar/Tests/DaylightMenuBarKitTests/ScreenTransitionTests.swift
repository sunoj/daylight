// XCTest coverage for popover screen transition resolution.
// Exports: ScreenTransitionTests
// Deps: XCTest, DaylightMenuBarKit

import XCTest
@testable import DaylightMenuBarKit

final class ScreenTransitionTests: XCTestCase {
    func testSettingsToHolidaysPushesFromTrailing() {
        let from = state(screen: .settings)
        let to = state(screen: .holidays)
        XCTAssertEqual(ScreenTransition.resolve(from: from, to: to), .push(fromTrailing: true))
    }

    func testHolidaysToSettingsPushesFromLeading() {
        let from = state(screen: .holidays)
        let to = state(screen: .settings)
        XCTAssertEqual(ScreenTransition.resolve(from: from, to: to), .push(fromTrailing: false))
    }

    func testCalendarToLunaFades() {
        let from = state(screen: .calendar)
        let to = state(screen: .luna)
        XCTAssertEqual(ScreenTransition.resolve(from: from, to: to), .fade)
    }

    func testMonthToYearZoomsFrom106() {
        let from = state(viewMode: .month)
        let to = state(viewMode: .year)
        XCTAssertEqual(ScreenTransition.resolve(from: from, to: to), .zoom(from: 1.06))
    }

    func testYearToMonthZoomsFrom094() {
        let from = state(viewMode: .year)
        let to = state(viewMode: .month)
        XCTAssertEqual(ScreenTransition.resolve(from: from, to: to), .zoom(from: 0.94))
    }

    func testNextMonthPushesFromTrailing() {
        let from = state(visibleMonth: LocalDate(year: 2026, month: 3, day: 1))
        let to = state(visibleMonth: LocalDate(year: 2026, month: 4, day: 1))
        XCTAssertEqual(ScreenTransition.resolve(from: from, to: to), .push(fromTrailing: true))
    }

    func testPreviousMonthPushesFromLeading() {
        let from = state(visibleMonth: LocalDate(year: 2026, month: 4, day: 1))
        let to = state(visibleMonth: LocalDate(year: 2026, month: 3, day: 1))
        XCTAssertEqual(ScreenTransition.resolve(from: from, to: to), .push(fromTrailing: false))
    }

    func testSelectingDifferentDayInSameMonthIsNone() {
        let from = state(selectedDate: LocalDate(year: 2026, month: 6, day: 10))
        let to = state(selectedDate: LocalDate(year: 2026, month: 6, day: 15))
        XCTAssertEqual(ScreenTransition.resolve(from: from, to: to), .none)
    }

    func testIdenticalStateIsNone() {
        let current = state()
        XCTAssertEqual(ScreenTransition.resolve(from: current, to: current), .none)
    }

    private func state(
        screen: PopoverScreen = .calendar,
        viewMode: CalendarViewMode = .month,
        visibleMonth: LocalDate = LocalDate(year: 2026, month: 6, day: 1),
        selectedDate: LocalDate = LocalDate(year: 2026, month: 6, day: 15)
    ) -> PopoverRenderState {
        PopoverRenderState(
            screen: screen,
            viewMode: viewMode,
            visibleMonth: visibleMonth,
            selectedDate: selectedDate
        )
    }
}
