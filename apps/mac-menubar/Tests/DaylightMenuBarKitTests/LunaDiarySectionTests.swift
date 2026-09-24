// Luna diary section rendering, composer, and Sol regression coverage.
// Exports: LunaDiarySectionTests
// Deps: XCTest, AppKit, DaylightMenuBarKit

import AppKit
import XCTest
@testable import DaylightMenuBarKit

@MainActor
final class LunaDiarySectionTests: XCTestCase {
    @MainActor
    func testLunaScreenWithThoughtsRendersDiaryTimeline() {
        let store = makeStore()
        let date = LocalDate(year: 2026, month: 8, day: 20)
        store.addThought(for: date, content: "first")
        store.addThought(for: date, content: "second")

        let controller = makeLunaController(store: store, selectedDate: date)
        _ = controller.view

        guard let timeline = firstSubview(of: DiaryThoughtTimelineView.self, in: controller.view) else {
            return XCTFail("DiaryThoughtTimelineView not found")
        }
        XCTAssertGreaterThan(timeline.fittingSize.height, 0)
    }

    @MainActor
    func testLunaScreenWithNoThoughtsAndClosedComposerHidesDiarySection() {
        let controller = makeLunaController()
        _ = controller.view
        XCTAssertFalse(controller.lunaDiaryComposing)

        XCTAssertNil(firstSubview(of: DiaryThoughtTimelineView.self, in: controller.view))
        XCTAssertFalse(containsDiaryHeader(in: controller.view))
    }

    @MainActor
    func testFooterNewEntryButtonOpensComposer() {
        let controller = makeLunaController()
        _ = controller.view
        XCTAssertFalse(controller.lunaDiaryComposing)

        guard let button = newThoughtButton(in: controller.view) else {
            return XCTFail("footer new-entry button not found")
        }
        button.mouseDown(with: NSEvent())
        XCTAssertTrue(controller.lunaDiaryComposing)
        XCTAssertTrue(quickDiaryInputRowVisible(in: controller.view))
    }

    @MainActor
    func testEscapeWhileComposingClearsComposerAndConsumesKey() {
        let controller = makeLunaController()
        _ = controller.view
        controller.lunaDiaryComposing = true
        controller.render()

        let event = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "",
            charactersIgnoringModifiers: "",
            isARepeat: false,
            keyCode: 53
        )!
        XCTAssertTrue(controller.handleKeyDown(event))
        XCTAssertFalse(controller.lunaDiaryComposing)
    }

    @MainActor
    func testSolQuickDiarySectionStillRendersTimelineAndInputRow() {
        let store = makeStore()
        let date = LocalDate(year: 2026, month: 8, day: 20)
        store.addThought(for: date, content: "sol note")

        let controller = PopoverViewController(store: store, calendarModel: CalendarModel(), onDataChanged: {})
        controller.selectedDate = date
        let section = controller.quickDiarySection()
        section.layoutSubtreeIfNeeded()

        XCTAssertNotNil(firstSubview(of: DiaryThoughtTimelineView.self, in: section))
        XCTAssertTrue(quickDiaryInputRowVisible(in: section))
    }

    @MainActor
    private func makeLunaController(
        store: DaylightStore? = nil,
        selectedDate: LocalDate = LocalDate(year: 2026, month: 8, day: 20)
    ) -> PopoverViewController {
        let store = store ?? makeStore()
        var settings = store.settings()
        settings.uiMode = "luna"
        store.saveSettings(settings)

        let controller = PopoverViewController(store: store, calendarModel: CalendarModel(), onDataChanged: {})
        controller.selectedDate = selectedDate
        controller.visibleMonth = LocalDate(year: selectedDate.year, month: selectedDate.month, day: 1)
        controller.show(.luna)
        return controller
    }

    @MainActor
    private func makeStore() -> DaylightStore {
        let defaults = UserDefaults(suiteName: "daylight.luna-diary.\(UUID().uuidString)")!
        let store = DaylightStore(defaults: defaults)
        var settings = store.settings()
        settings.language = "zh"
        store.saveSettings(settings)
        return store
    }

    @MainActor
    private func firstSubview<T: NSView>(of type: T.Type, in view: NSView) -> T? {
        if let match = view as? T { return match }
        for subview in view.subviews {
            if let match = firstSubview(of: type, in: subview) { return match }
        }
        return nil
    }

    @MainActor
    private func containsDiaryHeader(in view: NSView) -> Bool {
        let title = L("日记").uppercased()
        var found = false
        func walk(_ v: NSView) {
            if let field = v as? NSTextField, field.stringValue == title { found = true }
            v.subviews.forEach(walk)
        }
        walk(view)
        return found
    }

    @MainActor
    private func newThoughtButton(in view: NSView) -> RowButton? {
        guard let footer = firstSubview(of: LunaFooterView.self, in: view) else { return nil }
        var match: RowButton?
        func walk(_ v: NSView) {
            if let button = v as? RowButton, button.toolTip == L("新建日记") { match = button }
            v.subviews.forEach(walk)
        }
        walk(footer)
        return match
    }

    @MainActor
    private func quickDiaryInputRowVisible(in view: NSView) -> Bool {
        var fieldFound = false
        func walk(_ v: NSView) {
            if let field = v as? NSTextField, field.isEditable, !field.isBezeled { fieldFound = true }
            v.subviews.forEach(walk)
        }
        walk(view)
        return fieldFound
    }
}
