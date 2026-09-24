// Layout coverage for Sol's selected-day agenda section.
// Exports: SolCalendarAgendaLayoutTests
// Deps: XCTest, AppKit, DaylightMenuBarKit

import AppKit
import XCTest
@testable import DaylightMenuBarKit

@MainActor
final class SolCalendarAgendaLayoutTests: XCTestCase {
    func testAgendaIsOmittedWhenTheSelectedDayHasNoContent() {
        let controller = makeController()

        let screen = controller.calendarScreen(eventsByDay: [:])

        XCTAssertNil(firstSubview(of: SolCalendarAgendaSection.self, in: screen))
    }

    func testSeveralEventsUseTheCappedAgendaScrollHeight() {
        let controller = makeController()
        let events = (0..<8).map { event(id: "\($0)", offset: TimeInterval($0 * 3_600)) }
        let screen = controller.calendarScreen(eventsByDay: [controller.selectedDate.key: events])

        let height = fittingHeight(of: screen)
        guard let agenda = firstSubview(of: SolCalendarAgendaSection.self, in: screen),
              let scroll = firstSubview(of: NSScrollView.self, in: agenda) else {
            return XCTFail("Expected a selected-day agenda with a scroll view")
        }

        XCTAssertEqual(height, 716, accuracy: 0.5)
        XCTAssertEqual(scroll.frame.height, Metrics.solAgendaMaxHeight, accuracy: 0.5)
    }

    private func makeController() -> PopoverViewController {
        let defaults = UserDefaults(suiteName: "daylight.sol-agenda.\(UUID().uuidString)")!
        let store = DaylightStore(defaults: defaults)
        var settings = store.settings()
        settings.uiMode = "sol"
        settings.showLunarDate = true
        settings.systemCalendarEnabled = false
        store.saveSettings(settings)
        return PopoverViewController(store: store, calendarModel: CalendarModel(), onDataChanged: {})
    }

    private func event(id: String, offset: TimeInterval) -> CalendarEvent {
        let start = Date().addingTimeInterval(offset)
        return CalendarEvent(
            id: id,
            externalId: nil,
            title: "Event \(id)",
            start: start,
            end: start.addingTimeInterval(1_800),
            isAllDay: false,
            calendarId: "calendar",
            calendarTitle: "Calendar",
            colorHex: "336699",
            location: nil,
            videoURL: nil
        )
    }

    private func fittingHeight(of view: NSView) -> CGFloat {
        view.widthAnchor.constraint(equalToConstant: Metrics.popoverWidth).isActive = true
        view.layoutSubtreeIfNeeded()
        return view.fittingSize.height
    }

    private func firstSubview<T: NSView>(of type: T.Type, in view: NSView) -> T? {
        if let match = view as? T { return match }
        for subview in view.subviews {
            if let match = firstSubview(of: type, in: subview) { return match }
        }
        return nil
    }
}
