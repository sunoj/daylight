// Regression coverage for diary notes that overflow the popover.
// Exports: DiaryThoughtOverflowTests
// Deps: XCTest, AppKit, DaylightMenuBarKit

import AppKit
import XCTest
@testable import DaylightMenuBarKit

@MainActor
final class DiaryThoughtOverflowTests: XCTestCase {
    private static let longNote = String(repeating: "A long reflective note that keeps going ", count: 5)

    /// A note's unwrapped width used to become the popover's width: one long
    /// note widened Luna from 300pt to 717pt and Sol from 412pt to 715pt.
    func testLongNoteWrapsInsteadOfWideningThePopover() throws {
        for (mode, width) in [("luna", Metrics.lunaPopoverWidth), ("sol", Metrics.popoverWidth)] {
            for notes in [[Self.longNote], ["Short"] + [Self.longNote] + (1...7).map { "Note \($0)" }] {
                let (controller, cleanup) = makeController(mode: mode, notes: notes)
                defer { cleanup() }
                let root = controller.view
                let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: width, height: 600),
                                      styleMask: .borderless, backing: .buffered, defer: false)
                window.contentView = root
                window.layoutIfNeeded()
                XCTAssertEqual(root.fittingSize.width, width, accuracy: 0.5, "\(mode), \(notes.count) notes: popover widened")
            }
        }
    }

    /// Past four or five notes the rows were compressed onto each other instead
    /// of the list scrolling: the scroll view's height hug tied with the labels'
    /// compression resistance.
    func testManyNotesKeepFullHeightRowsAndScroll() throws {
        let notes = (1...9).map { "Note \($0)" } + [Self.longNote]
        for mode in ["luna", "sol"] {
            let (controller, cleanup) = makeController(mode: mode, notes: notes)
            defer { cleanup() }
            let root = controller.view
            let window = NSWindow(contentRect: NSRect(origin: .zero, size: root.fittingSize),
                                  styleMask: .borderless, backing: .buffered, defer: false)
            window.contentView = root
            root.layoutSubtreeIfNeeded()

            let timeline = try XCTUnwrap(find(DiaryThoughtTimelineView.self, in: root), mode)
            let scroll = try XCTUnwrap(find(NSScrollView.self, in: timeline), mode)
            let document = try XCTUnwrap(scroll.documentView, mode)
            let rows = deleteButtons(in: document)
                .map { $0.superview!.convert($0.superview!.bounds, to: document) }
                .sorted { $0.minY < $1.minY }
            XCTAssertEqual(rows.count, notes.count, mode)
            for row in rows { XCTAssertGreaterThanOrEqual(row.height, 16, "\(mode) row squashed to \(row.height)pt") }
            for (a, b) in zip(rows, rows.dropFirst()) {
                XCTAssertLessThanOrEqual(a.maxY, b.minY + 0.5, "\(mode) rows overlap")
            }
            let tallest = rows.map(\.height).max() ?? 0
            let shortest = rows.map(\.height).min() ?? 0
            XCTAssertGreaterThan(tallest, shortest * 1.8, "\(mode) long note did not wrap onto several lines")
            XCTAssertGreaterThan(document.frame.height, scroll.contentView.bounds.height,
                                 "\(mode) overflowing notes must scroll")
        }
    }

    private func makeController(mode: String, notes: [String]) -> (PopoverViewController, () -> Void) {
        let suite = "daylight.diary-overflow.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let store = DaylightStore(defaults: defaults)
        var settings = store.settings()
        settings.uiMode = mode
        settings.language = "en"
        settings.systemCalendarEnabled = false
        store.saveSettings(settings)
        let date = LocalDate(year: 2026, month: 9, day: 23)
        notes.forEach { store.addThought(for: date, content: $0, done: false) }
        let previous = Loc.language
        Loc.language = .en
        let controller = PopoverViewController(store: store, calendarModel: CalendarModel(), onDataChanged: {})
        controller.selectedDate = date
        controller.visibleMonth = LocalDate(year: 2026, month: 9, day: 1)
        _ = controller.view
        controller.render()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        controller.view.layoutSubtreeIfNeeded()
        return (controller, {
            Loc.language = previous
            defaults.removePersistentDomain(forName: suite)
        })
    }

    private func find<T: NSView>(_ type: T.Type, in view: NSView) -> T? {
        if let match = view as? T { return match }
        for subview in view.subviews { if let match = find(type, in: subview) { return match } }
        return nil
    }

    private func deleteButtons(in view: NSView) -> [DiaryThoughtDeleteButton] {
        (view as? DiaryThoughtDeleteButton).map { [$0] } ?? view.subviews.flatMap(deleteButtons)
    }
}
