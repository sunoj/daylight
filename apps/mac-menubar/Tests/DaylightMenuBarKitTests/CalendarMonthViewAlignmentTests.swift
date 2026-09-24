// Geometric alignment of the week-number column with the date numbers.
// Exports: CalendarMonthViewAlignmentTests
// Deps: XCTest, AppKit, DaylightMenuBarKit

import AppKit
import XCTest
@testable import DaylightMenuBarKit

final class CalendarMonthViewAlignmentTests: XCTestCase {
    /// With 农历 off but a holiday name present (tall grid), the week number
    /// must sit at the same vertical center as the date numbers.
    @MainActor func testWeekNumberAlignsWithDateInTallGrid() {
        let view = makeMonthView(withHolidayNamed: "假期", on: LocalDate(year: 2026, month: 7, day: 28))
        assertWeekAlignedWithDate(in: view, dayText: "15")
    }

    /// With 农历 off and no holiday names (compact grid), they must also align.
    @MainActor func testWeekNumberAlignsWithDateInCompactGrid() {
        let view = makeMonthView(withHolidayNamed: nil, on: nil)
        assertWeekAlignedWithDate(in: view, dayText: "15")
    }

    // MARK: Helpers

    @MainActor private func makeMonthView(withHolidayNamed name: String?, on date: LocalDate?) -> CalendarMonthView {
        let defaults = UserDefaults(suiteName: "daylight.alignment.\(UUID().uuidString)")!
        let store = DaylightStore(defaults: defaults)
        var settings = store.settings()
        settings.showLunarDate = false
        settings.showWeekNumbers = true
        settings.calendarType = CalendarWeekRule.us.rawValue // Sunday-first, like the screenshot
        store.saveSettings(settings)
        if let name, let date {
            store.replacePublicDays([PublicCalendarDay(date: date.key, type: "holiday", name: name, isImportant: true)])
        }

        let view = CalendarMonthView(
            store: store,
            calendarModel: CalendarModel(),
            lunarCalendar: LunarCalendar(),
            config: CalendarMonthViewConfig(
                year: 2026, month: 7,
                selectedDate: LocalDate(year: 2026, month: 7, day: 23),
                settings: store.settings()
            ),
            onSelectDate: { _ in }
        )
        view.frame = NSRect(x: 0, y: 0, width: Metrics.popoverWidth, height: 400)
        view.layoutSubtreeIfNeeded()
        return view
    }

    @MainActor private func assertWeekAlignedWithDate(in view: CalendarMonthView, dayText: String, file: StaticString = #filePath, line: UInt = #line) {
        var labels: [NSTextField] = []
        collectLabels(view, into: &labels)

        guard let dayLabel = labels.first(where: { $0.stringValue == dayText && $0.font?.pointSize ?? 0 > 12 }) else {
            return XCTFail("date label \(dayText) not found", file: file, line: line)
        }
        let dayCenterY = view.convert(dayLabel.bounds, from: dayLabel).midY

        // Week-number labels: small font, leading column (low x), numeric, not "#".
        let weekCandidates = labels.filter { label in
            guard let size = label.font?.pointSize, size < 12 else { return false }
            guard Int(label.stringValue) != nil else { return false }
            return view.convert(label.bounds, from: label).midX < 30
        }
        XCTAssertFalse(weekCandidates.isEmpty, "no week-number labels found", file: file, line: line)

        let closest = weekCandidates.min { a, b in
            abs(view.convert(a.bounds, from: a).midY - dayCenterY) < abs(view.convert(b.bounds, from: b).midY - dayCenterY)
        }!
        let weekCenterY = view.convert(closest.bounds, from: closest).midY
        XCTAssertEqual(weekCenterY, dayCenterY, accuracy: 1.0, "week number not aligned with date number", file: file, line: line)
    }

    @MainActor private func collectLabels(_ view: NSView, into labels: inout [NSTextField]) {
        if let field = view as? NSTextField { labels.append(field) }
        for subview in view.subviews { collectLabels(subview, into: &labels) }
    }
}
