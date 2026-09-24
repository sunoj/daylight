// Regression coverage for settings segmented-control labels.
// Exports: CalendarSettingsLayoutTests
// Deps: XCTest, AppKit, DaylightMenuBarKit

import AppKit
import XCTest
@testable import DaylightMenuBarKit

@MainActor
final class CalendarSettingsLayoutTests: XCTestCase {
    @MainActor
    func testSettingsPopoverUsesNormalWidthForLunaAndSol() {
        for mode in ["luna", "sol"] {
            let defaults = UserDefaults(suiteName: "daylight.settings-width.\(mode).\(UUID().uuidString)")!
            let store = DaylightStore(defaults: defaults)
            var settings = store.settings()
            settings.uiMode = mode
            store.saveSettings(settings)

            let controller = PopoverViewController(store: store, calendarModel: CalendarModel(), onDataChanged: {})
            _ = controller.view
            controller.show(.settings)

            XCTAssertEqual(controller.preferredContentSize.width, Metrics.popoverWidth)
        }
    }

    @MainActor
    func testSettingsHeaderCloseControlStaysInsidePanel() {
        let store = DaylightStore(defaults: UserDefaults(suiteName: "daylight.settings-header.\(UUID().uuidString)")!)
        let panel = CalendarSettingsPanel(
            store: store,
            onDataChanged: {},
            onNeedsRender: {},
            onClose: {},
            onOpenStatusEditor: {},
            onOpenHolidays: {},
            onOpenSystemCalendar: {},
            onToast: { _ in }
        )
        panel.frame = NSRect(x: 0, y: 0, width: Metrics.popoverWidth - 28, height: 1_000)
        panel.layoutSubtreeIfNeeded()

        guard let close = rowButtons(in: panel).first else {
            return XCTFail("settings header close control not found")
        }
        let frame = panel.convert(close.bounds, from: close)
        XCTAssertGreaterThanOrEqual(frame.minX, 0)
        XCTAssertLessThanOrEqual(frame.maxX, panel.bounds.maxX)
        XCTAssertGreaterThanOrEqual(frame.maxX, panel.bounds.maxX - 40)
        XCTAssertGreaterThanOrEqual(frame.maxY, panel.bounds.maxY - 60)
    }

    func testSegmentLabelsAreSingleLineAndTailTruncated() {
        let control = SegmentedControl(items: ["Luna", "Sol"], selectedIndex: 0, onChange: { _ in })
        let labels = textFields(in: control)

        XCTAssertEqual(labels.count, 2)
        for label in labels {
            XCTAssertTrue(label.usesSingleLineMode)
            XCTAssertEqual(label.maximumNumberOfLines, 1)
            XCTAssertEqual(label.lineBreakMode, NSLineBreakMode.byTruncatingTail)
        }
    }

    private func textFields(in view: NSView) -> [NSTextField] {
        view.subviews.flatMap { subview in
            (subview as? NSTextField).map { [$0] } ?? textFields(in: subview)
        }
    }

    private func rowButtons(in view: NSView) -> [RowButton] {
        view.subviews.flatMap { subview in
            (subview as? RowButton).map { [$0] } ?? rowButtons(in: subview)
        }
    }
}
