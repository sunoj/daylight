// XCTest coverage for month grid date-cell layout.
// Exports: CalendarDateCellTests
// Deps: XCTest, AppKit, DaylightMenuBarKit

import AppKit
import XCTest
@testable import DaylightMenuBarKit

final class CalendarDateCellTests: XCTestCase {
    func testCellWithLongSubtitleAndThreeHolidayDotsFitsFixedHeight() {
        let title = CalendarDayTitle(
            primary: "17",
            secondary: "立春立春立春",
            isSolarTerm: true,
            holidayColorIds: ["rust", "stone", "olive", "amber"]
        )
        let state = CalendarDateCellState(title: title, isToday: false, isSelected: false, isOutsideMonth: false, isWeekend: false)
        let cell = CalendarDateCell(state: state, target: nil, action: Selector(("noop:")))
        cell.setFrameSize(NSSize(width: 44, height: Metrics.cellHeight))

        cell.layoutSubtreeIfNeeded()

        XCTAssertEqual(cell.bounds.height, Metrics.cellHeight)
        XCTAssertFalse(cell.hasAmbiguousLayout)
        XCTAssertTrue(cell.subviews.allSatisfy { cell.bounds.insetBy(dx: -0.5, dy: -0.5).contains($0.frame) })
    }

    func testCellWithoutSubtitleUsesCompactHeight() {
        let title = CalendarDayTitle(primary: "17", secondary: nil, isSolarTerm: false, holidayColorIds: [])
        let state = CalendarDateCellState(
            title: title, isToday: false, isSelected: false, isOutsideMonth: false, isWeekend: false, showsSubtitle: false
        )
        let cell = CalendarDateCell(state: state, target: nil, action: Selector(("noop:")))

        XCTAssertEqual(cell.fittingSize.height, Metrics.compactCellHeight)
        XCTAssertLessThan(Metrics.compactCellHeight, Metrics.cellHeight)
    }
}
