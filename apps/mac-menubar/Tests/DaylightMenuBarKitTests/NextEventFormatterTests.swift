// Tests for pure next-event selection and relative-time formatting.
// Exports: NextEventFormatterTests
// Deps: XCTest, DaylightMenuBarKit, Foundation

import Foundation
import XCTest
@testable import DaylightMenuBarKit

final class NextEventFormatterTests: XCTestCase {
    func testNextSkipsAllDayAndEndedEvents() {
        let now = Date(timeIntervalSince1970: 1_000)
        let allDay = event("all-day", start: 900, end: 1_100, allDay: true)
        let ended = event("ended", start: 500, end: 900)
        let next = event("next", start: 1_100, end: 1_200)

        XCTAssertEqual(NextEventFormatter.next(in: [allDay, ended, next], now: now)?.id, "next")
    }

    func testNextReturnsNilForEmptyInput() {
        XCTAssertNil(NextEventFormatter.next(in: [], now: Date()))
    }

    func testNextReturnsNilWhenOnlyAllDayEventsExist() {
        let now = Date(timeIntervalSince1970: 1_000)
        let allDay = event("all-day", start: 900, end: 1_100, allDay: true)

        XCTAssertNil(NextEventFormatter.next(in: [allDay], now: now))
    }

    func testRelativeUsesNowWhenEventHasStarted() {
        // Pinned like the English case below. `Loc.language` is global and every
        // render sets it from the store, whose default follows the system — so a
        // rendering test running earlier in the suite decided this one's output.
        let previous = Loc.language
        defer { Loc.language = previous }
        Loc.language = .zh

        XCTAssertEqual(
            NextEventFormatter.relative(to: Date(timeIntervalSince1970: 900), from: Date(timeIntervalSince1970: 1_000)),
            "现在"
        )
    }

    func testRelativeRoundsDownMinutesAndHoursInEnglish() {
        let previous = Loc.language
        defer { Loc.language = previous }
        Loc.language = .en

        let now = Date(timeIntervalSince1970: 1_000)
        XCTAssertEqual(NextEventFormatter.relative(to: now.addingTimeInterval(38 * 60 + 59), from: now), "in 38 min.")
        XCTAssertEqual(NextEventFormatter.relative(to: now.addingTimeInterval(2 * 60 * 60 + 59), from: now), "in 2 h")
    }

    func testRelativeReturnsNilBeyond24Hours() {
        let now = Date(timeIntervalSince1970: 1_000)

        XCTAssertNil(NextEventFormatter.relative(to: now.addingTimeInterval(24 * 60 * 60 + 1), from: now))
    }

    private func event(_ id: String, start: TimeInterval, end: TimeInterval, allDay: Bool = false) -> CalendarEvent {
        CalendarEvent(
            id: id,
            externalId: nil,
            title: id,
            start: Date(timeIntervalSince1970: start),
            end: Date(timeIntervalSince1970: end),
            isAllDay: allDay,
            calendarId: "calendar",
            calendarTitle: "Calendar",
            colorHex: "336699",
            location: nil,
            videoURL: nil
        )
    }
}
