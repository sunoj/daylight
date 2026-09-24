// Luna's month/year/decade picker: entry, exit, and what its shell keeps.
// Exports: LunaPeriodPickerTests
// Deps: XCTest, AppKit, DaylightMenuBarKit

import AppKit
import XCTest
@testable import DaylightMenuBarKit

@MainActor
final class LunaPeriodPickerTests: XCTestCase {
    @MainActor
    func testTappingTheTitleZoomsOutInsteadOfLeavingLuna() {
        let controller = makeController()
        _ = controller.view
        XCTAssertEqual(controller.viewMode, .month)

        tapHeaderTitle(in: controller)
        XCTAssertEqual(controller.viewMode, .year)
        XCTAssertEqual(controller.screen, .luna, "the picker must stay in Luna's shell")

        tapHeaderTitle(in: controller)
        XCTAssertEqual(controller.viewMode, .decade)
    }

    /// The title took over the tap that used to jump to today, so today has to
    /// have kept an affordance of its own.
    @MainActor
    func testTodayIsStillReachableFromTheHeader() {
        let controller = makeController()
        _ = controller.view
        controller.selectDate(LocalDate(year: 2020, month: 3, day: 9))
        XCTAssertNotEqual(controller.selectedDate, controller.calendarModel.today())

        // The pill is [previous, today, next]; the middle control jumps to today.
        let pill = navigationButtons(in: controller)
        XCTAssertEqual(pill.count, 3)
        pill[1].mouseDown(with: NSEvent())
        XCTAssertEqual(controller.selectedDate, controller.calendarModel.today())
    }

    @MainActor
    func testEscapeStepsBackIntoTheMonthRatherThanClosing() {
        let controller = makeController()
        _ = controller.view
        controller.viewMode = .decade
        controller.render()

        XCTAssertTrue(controller.handleKeyDown(escape()))
        XCTAssertEqual(controller.viewMode, .month)
        // With the month already showing, escape is the popover's again.
        XCTAssertFalse(controller.handleKeyDown(escape()))
    }

    /// The picker has no selected day to write against, so the footer's
    /// new-entry button — and any open composer — must not survive the zoom.
    @MainActor
    func testPickerDropsTheDiaryComposer() {
        let controller = makeController()
        _ = controller.view
        controller.lunaDiaryComposing = true
        controller.render()
        XCTAssertNotNil(firstSubview(of: NSTextField.self, in: controller.view, where: { $0.isEditable }))

        controller.zoomOut()
        XCTAssertFalse(controller.lunaDiaryComposing)
        XCTAssertNil(firstSubview(of: NSTextField.self, in: controller.view, where: { $0.isEditable }))
    }

    @MainActor
    func testPickerKeepsSettingsReachableAndFitsLunasWidth() {
        let controller = makeController()
        _ = controller.view
        controller.zoomOut()

        XCTAssertNotNil(firstSubview(of: LunaFooterView.self, in: controller.view))
        XCTAssertEqual(controller.preferredContentSize.width, Metrics.lunaPopoverWidth, accuracy: 0.5)
        XCTAssertGreaterThan(controller.preferredContentSize.height, 1)
    }

    @MainActor
    func testPickingAMonthReturnsToTheGrid() {
        let controller = makeController()
        _ = controller.view
        controller.zoomOut()
        guard let march = firstSubview(of: CalendarPeriodButton.self, in: controller.view, where: {
            $0.targetDate?.month == 3
        }) else {
            return XCTFail("no month tiles in the picker")
        }

        march.mouseDown(with: NSEvent())
        XCTAssertEqual(controller.viewMode, .month)
        XCTAssertEqual(controller.visibleMonth.month, 3)
    }

    @MainActor
    private func makeController() -> PopoverViewController {
        let defaults = UserDefaults(suiteName: "daylight.luna-picker.\(UUID().uuidString)")!
        let store = DaylightStore(defaults: defaults)
        var settings = store.settings()
        settings.uiMode = "luna"
        store.saveSettings(settings)
        return PopoverViewController(store: store, calendarModel: CalendarModel(), onDataChanged: {})
    }

    @MainActor
    private func escape() -> NSEvent {
        NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0,
            windowNumber: 0, context: nil, characters: "\u{1B}",
            charactersIgnoringModifiers: "\u{1B}", isARepeat: false, keyCode: 53
        )!
    }

    @MainActor
    private func tapHeaderTitle(in controller: PopoverViewController) {
        guard let title = headerButtons(in: controller).first else {
            return XCTFail("no header title button")
        }
        title.mouseDown(with: NSEvent())
    }

    /// The header's first RowButton is the title; the pill's three follow it.
    @MainActor
    private func headerButtons(in controller: PopoverViewController) -> [RowButton] {
        guard let header = firstSubview(of: LunaHeaderView.self, in: controller.view, where: { _ in true }) else { return [] }
        return collect(RowButton.self, in: header)
    }

    @MainActor
    private func navigationButtons(in controller: PopoverViewController) -> [RowButton] {
        Array(headerButtons(in: controller).dropFirst())
    }

    @MainActor
    private func collect<T: NSView>(_ type: T.Type, in view: NSView) -> [T] {
        var found: [T] = []
        if let match = view as? T { found.append(match) }
        view.subviews.forEach { found += collect(type, in: $0) }
        return found
    }

    @MainActor
    private func firstSubview<T: NSView>(of type: T.Type, in view: NSView, where match: (T) -> Bool = { _ in true }) -> T? {
        collect(type, in: view).first(where: match)
    }
}
