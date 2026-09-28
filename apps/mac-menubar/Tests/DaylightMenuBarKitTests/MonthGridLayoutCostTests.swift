// Guards the month grids against drifting back to Auto Layout.
// Exports: MonthGridLayoutCostTests
// Deps: XCTest, AppKit, DaylightMenuBarKit

import AppKit
import XCTest
@testable import DaylightMenuBarKit

@MainActor
final class MonthGridLayoutCostTests: XCTestCase {
    /// Both grids are laid out by frame. With nested stack views and per-cell
    /// constraints, the 42-cell grid cost ~40ms of Auto Layout on every render
    /// and made each month step visibly lag; keep their subtrees constraint-free.
    func testMonthGridsCarryNoInternalConstraints() {
        let defaults = UserDefaults(suiteName: "daylight.grid-cost.\(UUID().uuidString)")!
        defer { defaults.removePersistentDomain(forName: "daylight.grid-cost") }
        let store = DaylightStore(defaults: defaults)
        var settings = store.settings()
        settings.showWeekNumbers = true
        store.saveSettings(settings)
        let date = LocalDate(year: 2026, month: 9, day: 23)
        let luna = LunaMonthGridView(
            store: store, calendarModel: CalendarModel(), lunarCalendar: LunarCalendar(),
            year: 2026, month: 9, selectedDate: date, settings: store.settings(), eventsByDay: [:], onSelectDate: { _ in }
        )
        let sol = CalendarMonthView(
            store: store, calendarModel: CalendarModel(), lunarCalendar: LunarCalendar(),
            config: CalendarMonthViewConfig(year: 2026, month: 9, selectedDate: date, settings: store.settings()),
            onSelectDate: { _ in }
        )
        for (name, grid, width) in [("Luna", luna as NSView, Metrics.lunaPopoverWidth), ("Sol", sol, Metrics.popoverWidth - 28)] {
            grid.frame = NSRect(x: 0, y: 0, width: width, height: grid.fittingSize.height)
            grid.layoutSubtreeIfNeeded()
            XCTAssertEqual(constraintCount(in: grid), 0, "\(name) grid reintroduced Auto Layout constraints: \(constraints(in: grid))")
            XCTAssertEqual(cellFrames(in: grid).count, 42, name)
            XCTAssertTrue(cellFrames(in: grid).allSatisfy { $0.width > 20 && $0.height > 20 }, "\(name) cells not laid out")
        }
    }

    /// The app prewarms the popover before it has a window, so the grids lay out
    /// once with no backing scale and are then moved into a 2x window without a
    /// size change. Frames rounded against the wrong scale came out narrower
    /// than their text, and every date truncated to "…" in the real popover.
    func testLabelsStayWideEnoughWhenLaidOutBeforeAWindowExists() {
        for mode in ["luna", "sol"] {
            let defaults = UserDefaults(suiteName: "daylight.grid-prewarm.\(UUID().uuidString)")!
            let store = DaylightStore(defaults: defaults)
            var settings = store.settings()
            settings.uiMode = mode
            settings.systemCalendarEnabled = false
            settings.lunaShowLunarDate = true
            settings.showLunarDate = true
            store.saveSettings(settings)
            let controller = PopoverViewController(store: store, calendarModel: CalendarModel(), onDataChanged: {})
            controller.view.layoutSubtreeIfNeeded()

            let window = NSWindow(contentRect: NSRect(origin: .zero, size: controller.view.frame.size),
                                  styleMask: .borderless, backing: .buffered, defer: false)
            window.contentViewController = controller
            controller.view.layoutSubtreeIfNeeded()

            // A frame hugging the width measured before the window existed was
            // a hair short once drawn in the popover. Date labels must span
            // their cell's usable width with centred text instead, so they only
            // truncate when the cell genuinely cannot fit them.
            let labels = gridLabels(in: controller.view).filter { $0.font?.pointSize ?? 0 > 12 }
            XCTAssertGreaterThanOrEqual(labels.count, 42, mode)
            // Subtitles (lunar day, holiday name) take the full cell width: in
            // the live popover a three-character name needed ~33.5pt, more
            // than a 37pt column left after the circle's edge insets.
            let subtitles = gridLabels(in: controller.view).filter { ($0.font?.pointSize ?? 99) < 12 && $0.stringValue.count > 1 }
            XCTAssertFalse(subtitles.isEmpty, mode)
            for label in subtitles {
                XCTAssertEqual(label.frame.width, label.superview?.bounds.width ?? 0, accuracy: 0.5, "\(mode) subtitle '\(label.stringValue)'")
                XCTAssertEqual(label.alignment, .center, "\(mode) subtitle '\(label.stringValue)'")
            }
            for label in labels {
                let cellWidth = label.superview?.bounds.width ?? 0
                XCTAssertGreaterThanOrEqual(label.frame.width, cellWidth - 5, "\(mode) '\(label.stringValue)' hugs its text")
                XCTAssertEqual(label.alignment, .center, "\(mode) '\(label.stringValue)'")
            }
            defaults.removePersistentDomain(forName: "daylight.grid-prewarm")
        }
    }

    /// Frame layout must follow every size change. The real popover first laid
    /// the cells out while they were still narrow; when they grew, nothing
    /// re-ran `layout()`, so two-digit dates kept a one-digit frame and showed
    /// "…" — a failure no test caught because each one laid out only once.
    func testGridsRelayOutAfterGrowing() {
        let defaults = UserDefaults(suiteName: "daylight.grid-grow.\(UUID().uuidString)")!
        defer { defaults.removePersistentDomain(forName: "daylight.grid-grow") }
        let store = DaylightStore(defaults: defaults)
        var settings = store.settings()
        settings.lunaShowLunarDate = true
        settings.showWeekNumbers = true
        store.saveSettings(settings)
        let date = LocalDate(year: 2026, month: 9, day: 23)
        let luna = LunaMonthGridView(
            store: store, calendarModel: CalendarModel(), lunarCalendar: LunarCalendar(),
            year: 2026, month: 9, selectedDate: date, settings: store.settings(), eventsByDay: [:], onSelectDate: { _ in }
        )
        let sol = CalendarMonthView(
            store: store, calendarModel: CalendarModel(), lunarCalendar: LunarCalendar(),
            config: CalendarMonthViewConfig(year: 2026, month: 9, selectedDate: date, settings: store.settings()),
            onSelectDate: { _ in }
        )
        for (name, grid, width) in [("Luna", luna as NSView, Metrics.lunaPopoverWidth), ("Sol", sol, Metrics.popoverWidth - 28)] {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: width, height: 500),
                                  styleMask: .borderless, backing: .buffered, defer: false)
            let host = NSView(frame: NSRect(x: 0, y: 0, width: width, height: 500))
            window.contentView = host
            grid.translatesAutoresizingMaskIntoConstraints = true
            host.addSubview(grid)
            grid.frame = NSRect(x: 0, y: 0, width: 120, height: 400)
            host.layoutSubtreeIfNeeded()
            grid.frame = NSRect(x: 0, y: 0, width: width, height: 400)
            host.layoutSubtreeIfNeeded()
            let labels = gridLabels(in: grid).filter { !$0.stringValue.isEmpty }
            XCTAssertGreaterThanOrEqual(labels.count, 42, name)
            for label in labels {
                XCTAssertGreaterThanOrEqual(label.frame.width + 0.01, min(label.intrinsicContentSize.width, 20),
                                            "\(name) '\(label.stringValue)' kept its narrow frame after growing")
            }
        }
    }

    private func gridLabels(in view: NSView) -> [NSTextField] {
        if view is LunaDateCell || view is CalendarDateCell {
            return view.subviews.compactMap { $0 as? NSTextField }
        }
        return view.subviews.flatMap(gridLabels)
    }

    /// Frame-derived (autoresizing) and intrinsic-size constraints are how a
    /// frame-laid-out view talks to its parent; anything else is layout work.
    private func isLayoutConstraint(_ constraint: NSLayoutConstraint) -> Bool {
        let kind = String(describing: type(of: constraint))
        return !kind.contains("Autoresizing") && !kind.contains("ContentSize")
    }

    private func constraintCount(in view: NSView) -> Int {
        constraints(in: view).count
    }

    private func constraints(in view: NSView) -> [String] {
        view.constraints.filter(isLayoutConstraint).map { "\(type(of: view)): \($0)" }
            + view.subviews.flatMap(constraints)
    }

    private func cellFrames(in grid: NSView) -> [NSRect] {
        grid.subviews.filter { $0 is LunaDateCell || $0 is CalendarDateCell }.map(\.frame)
    }
}
