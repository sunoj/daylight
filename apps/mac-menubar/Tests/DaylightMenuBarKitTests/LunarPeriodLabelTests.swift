// Lunar labels shown in the year and decade pickers.
// Exports: LunarPeriodLabelTests
// Deps: XCTest, AppKit, DaylightMenuBarKit

import AppKit
import XCTest
@testable import DaylightMenuBarKit

final class LunarPeriodLabelTests: XCTestCase {
    private let lunar = LunarCalendar()

    /// 2029's lunar new year falls on 13 February. January therefore runs from
    /// 冬月 into 腊月, and February crosses the turn of the year into 正月.
    func testSpanAcrossTheLunarNewYear() {
        XCTAssertEqual(label(2029, 1), "冬月–腊月")
        XCTAssertEqual(label(2029, 2), "腊月–正月")
    }

    func testJulySpansTwoLunarMonths() {
        XCTAssertEqual(label(2029, 7), "五月–六月")
    }

    /// A leap month keeps its 闰 prefix rather than collapsing onto the月 it repeats.
    func testLeapMonthKeepsItsPrefix() {
        XCTAssertEqual(label(2028, 6), "五月–闰五月")
    }

    /// Every month of a decade must produce a label; a nil would silently blank
    /// a tile in the grid.
    func testEveryMonthOfADecadeHasALabel() {
        for year in 2020...2029 {
            for month in 1...12 {
                XCTAssertNotNil(
                    LunarPeriodLabel.monthSpan(year: year, month: month, lunarCalendar: lunar),
                    "\(year).\(month)"
                )
            }
        }
    }

    /// The label always names the lunar months of the first and last day, so it
    /// cannot contradict the day cells the month view then shows.
    func testLabelMatchesTheFirstAndLastDayOfEachMonth() {
        for month in 1...12 {
            guard let text = LunarPeriodLabel.monthSpan(year: 2026, month: month, lunarCalendar: lunar) else {
                return XCTFail("no label for 2026.\(month)")
            }
            let first = lunar.lunarDate(for: LocalDate(year: 2026, month: month, day: 1))
            XCTAssertTrue(text.hasPrefix("\(first?.monthName ?? "")月"), "2026.\(month) → \(text)")
        }
    }

    @MainActor
    func testYearGridShowsSpansOnlyWhenLunarCalendarIsSupplied() {
        let withLunar = CalendarPeriodGridView(
            visibleDate: LocalDate(year: 2029, month: 7, day: 1),
            selectedDate: LocalDate(year: 2029, month: 7, day: 1),
            mode: .year,
            lunarCalendar: lunar,
            onSelect: { _, _ in }
        )
        XCTAssertTrue(labels(in: withLunar).contains("五月–六月"))

        let withoutLunar = CalendarPeriodGridView(
            visibleDate: LocalDate(year: 2029, month: 7, day: 1),
            selectedDate: LocalDate(year: 2029, month: 7, day: 1),
            mode: .year,
            onSelect: { _, _ in }
        )
        XCTAssertFalse(labels(in: withoutLunar).contains { $0.hasSuffix("月–六月") })
    }

    /// 2029 is 己酉年 — the 干支 year that starts at its lunar new year, not the
    /// 戊申年 that the first six weeks of the Gregorian year still belong to.
    func testGregorianYearIsNamedByTheLunarYearItMostlyHolds() {
        XCTAssertEqual(LunarPeriodLabel.yearName(2029, lunarCalendar: lunar), "己酉年")
        XCTAssertEqual(LunarPeriodLabel.yearName(2026, lunarCalendar: lunar), "丙午年")
    }

    /// The 干支 cycle is sixty years long, so a year and its sixtieth successor
    /// share a name and every year in between differs.
    func testStemBranchNamesRepeatOnASixtyYearCycle() {
        let names = (2000...2059).compactMap { LunarPeriodLabel.yearName($0, lunarCalendar: lunar) }
        XCTAssertEqual(Set(names).count, 60)
        XCTAssertEqual(LunarPeriodLabel.yearName(2000, lunarCalendar: lunar),
                       LunarPeriodLabel.yearName(2060, lunarCalendar: lunar))
    }

    /// The decade grid lists years, so each tile carries its 干支 year.
    @MainActor
    func testDecadeGridLabelsEachYearWithItsStemBranch() {
        let grid = CalendarPeriodGridView(
            visibleDate: LocalDate(year: 2029, month: 7, day: 1),
            selectedDate: LocalDate(year: 2029, month: 7, day: 1),
            mode: .decade,
            lunarCalendar: lunar,
            onSelect: { _, _ in }
        )
        let text = labels(in: grid)
        XCTAssertTrue(text.contains("己酉年"), "expected 2029's 干支 year, got \(text)")
        XCTAssertFalse(text.contains { $0.contains("月") }, "years must not carry month spans")
    }

    /// Luna hosts the same grid in a 300pt shell; the four columns must divide
    /// that width, not Sol's.
    @MainActor
    func testGridHonoursACustomContentWidth() {
        let width = Metrics.lunaPopoverWidth - Metrics.contentInset * 2
        let grid = CalendarPeriodGridView(
            visibleDate: LocalDate(year: 2029, month: 7, day: 1),
            selectedDate: LocalDate(year: 2029, month: 7, day: 1),
            mode: .year,
            lunarCalendar: lunar,
            contentWidth: width,
            onSelect: { _, _ in }
        )
        XCTAssertEqual(grid.fittingSize.width, width, accuracy: 0.5)
    }

    private func label(_ year: Int, _ month: Int) -> String? {
        LunarPeriodLabel.monthSpan(year: year, month: month, lunarCalendar: lunar)
    }

    @MainActor
    private func labels(in view: NSView) -> [String] {
        if let field = view as? NSTextField { return [field.stringValue] }
        return view.subviews.flatMap { labels(in: $0) }
    }
}
