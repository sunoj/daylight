// Geometry guard for the Luna day cell's today/selected circle.
// Exports: LunaCellGeometryTests
// Deps: XCTest, AppKit, DaylightMenuBarKit

import XCTest
import AppKit
@testable import DaylightMenuBarKit

final class LunaCellGeometryTests: XCTestCase {
    /// The circle has twice been sized smaller than what it must contain: once
    /// from content height alone, leaving the two-digit number hanging out of
    /// its sides, and once per-cell, so a day with events got a different disc
    /// from one without. Measure it instead of eyeballing it.
    func testCircleContainsContent() {
        for showsSubtitle in [false, true] {
            let d = Metrics.lunaCircleDiameter(showsSubtitle: showsSubtitle)
            let cell = showsSubtitle ? Metrics.lunaCellHeightTall : Metrics.lunaCellHeight
            // widest two-digit number at the Luna number font
            let label = NSTextField(labelWithString: "28")
            label.font = Typography.mono(15, .medium)
            let numW = label.intrinsicContentSize.width
            let numH = label.intrinsicContentSize.height
            let dotsW = CGFloat(Metrics.lunaMaxDots) * Metrics.lunaDotSize
                + CGFloat(Metrics.lunaMaxDots - 1) * Metrics.lunaDotSpacing
            var contentH = numH
            if showsSubtitle { contentH += Metrics.lunaLabelStackSpacing + Metrics.lunaSubtitleLineHeight }
            contentH += Metrics.lunaDotRowGap + Metrics.lunaDotSize
            // chord width available at the dot row's centre offset below the circle centre
            let offset = contentH / 2 - Metrics.lunaDotSize / 2
            let r = d / 2
            let chord = 2 * (r * r - offset * offset > 0 ? (r * r - offset * offset).squareRoot() : 0)
            XCTAssertLessThanOrEqual(d, cell, "circle taller than the cell")
            XCTAssertLessThanOrEqual(numW, d, "number wider than its circle")
            XCTAssertLessThanOrEqual(dotsW, chord, "dot row wider than the circle at that height")
        }
    }

    /// Day numbers must sit at the same height whether or not the cell has event
    /// dots. Building the content stack only from the views a cell happened to
    /// have made the dotted cells taller, and centring that pushed their numbers
    /// up — one row showed numbers at three different heights.
    func testNumbersAlignAcrossCellsWithAndWithoutDots() {
        for showsSubtitle in [false, true] {
            let withDots = makeCell(dots: 2, showsSubtitle: showsSubtitle)
            let without = makeCell(dots: 0, showsSubtitle: showsSubtitle)
            let a = numberCentreY(in: withDots)
            let b = numberCentreY(in: without)
            XCTAssertEqual(a, b, accuracy: 0.5,
                           "number drifts \(a - b)pt when the cell has dots (subtitle=\(showsSubtitle))")
        }
    }

    private func makeCell(dots: Int, showsSubtitle: Bool) -> LunaDateCell {
        let date = LocalDate(year: 2026, month: 8, day: 19)
        let day = CalendarDay(date: date, isToday: false, isOutsideMonth: false)
        let title = CalendarDayTitle(
            primary: "19",
            secondary: showsSubtitle ? "初六" : nil,
            isSolarTerm: false,
            holidayColorIds: Array(repeating: "rust", count: dots)
        )
        let cell = LunaDateCell(day: day, title: title, events: [], selectedDate: date,
                                showsSubtitle: showsSubtitle, onSelectDate: { _ in })
        cell.frame = NSRect(x: 0, y: 0, width: 40,
                            height: showsSubtitle ? Metrics.lunaCellHeightTall : Metrics.lunaCellHeight)
        cell.layoutSubtreeIfNeeded()
        return cell
    }

    private func numberCentreY(in view: NSView) -> CGFloat {
        for sub in view.subviews {
            if let field = sub as? NSTextField, field.stringValue == "19" {
                return view.convert(field.frame, from: field.superview).midY
            }
            let nested = numberCentreY(in: sub)
            if nested >= 0 { return view.convert(NSRect(x: 0, y: nested, width: 0, height: 0), from: sub).midY }
        }
        return -1
    }
}
