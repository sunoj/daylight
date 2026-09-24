// Tests for pure event-list grouping and ordering.
// Exports: EventListSectionsTests
// Deps: XCTest, DaylightMenuBarKit, Foundation

import Foundation
import XCTest
@testable import DaylightMenuBarKit

final class EventListSectionsTests: XCTestCase {
    func testAllDayEventsAreSeparatedAndSortedByTitle() {
        let now = Date(timeIntervalSince1970: 1_000)
        let events = [
            event("z", title: "Zoo", start: 100, end: 200, allDay: true),
            event("a", title: "Alpha", start: 100, end: 200, allDay: true),
            event("t", title: "Timed", start: 900, end: 1_100)
        ]

        let sections = EventListSections.build(events: events, now: now)

        XCTAssertEqual(sections.allDay.map(\.title), ["Alpha", "Zoo"])
        XCTAssertTrue(sections.past.isEmpty)
        XCTAssertEqual(sections.upcoming.map(\.title), ["Timed"])
    }

    func testTimedEventsSplitAtNowAndSortByStart() {
        let now = Date(timeIntervalSince1970: 1_000)
        let events = [
            event("late", title: "Late", start: 1_300, end: 1_400),
            event("past", title: "Past", start: 600, end: 900),
            event("current", title: "Current", start: 700, end: 1_100),
            event("early", title: "Early", start: 1_100, end: 1_200)
        ]

        let sections = EventListSections.build(events: events, now: now)

        XCTAssertEqual(sections.past.map(\.id), ["past"])
        XCTAssertEqual(sections.upcoming.map(\.id), ["current", "early", "late"])
    }

    func testEmptyInputProducesEmptySections() {
        let sections = EventListSections.build(events: [], now: Date())

        XCTAssertTrue(sections.isEmpty)
        XCTAssertTrue(sections.holidays.isEmpty)
        XCTAssertTrue(sections.allDay.isEmpty)
        XCTAssertTrue(sections.past.isEmpty)
        XCTAssertTrue(sections.upcoming.isEmpty)
    }

    func testDayWithOnlyHolidayIsNotEmpty() {
        let holiday = HolidayDetailEntry(
            day: PublicCalendarDay(date: "2026-04-13", type: "holiday", name: "Songkran", isImportant: true),
            colorId: "amber",
            sourceId: "th",
            sourceName: "泰国",
            isRemote: false
        )
        let sections = EventListSections.build(holidays: [holiday], events: [], now: Date())

        XCTAssertFalse(sections.isEmpty)
        XCTAssertEqual(sections.holidays.count, 1)
        XCTAssertTrue(sections.allDay.isEmpty)
    }

    func testHolidaysSortAboveAllDayEvents() {
        let now = Date(timeIntervalSince1970: 1_000)
        let holiday = HolidayDetailEntry(
            day: PublicCalendarDay(date: "2026-02-17", type: "holiday", name: "春节", isImportant: true),
            colorId: "rust",
            sourceId: "cn",
            sourceName: "中国大陆",
            isRemote: false
        )
        let allDay = event("a", title: "Alpha", start: 100, end: 200, allDay: true)
        let sections = EventListSections.build(holidays: [holiday], events: [allDay], now: now)

        XCTAssertEqual(sections.rowOrderIDs, ["holiday:2026-02-17:春节", "allday:a"])
    }
    func testRowOrderPlacesTimedEventsAfterHolidaysAndAllDayEvents() {
        let now = Date(timeIntervalSince1970: 1_000)
        let holiday = HolidayDetailEntry(
            day: PublicCalendarDay(date: "2026-02-17", type: "holiday", name: "春节", isImportant: true),
            colorId: "rust",
            sourceId: "cn",
            sourceName: "中国大陆",
            isRemote: false
        )
        let events = [
            event("late", title: "Late", start: 1_300, end: 1_400),
            event("all-day", title: "All day", start: 0, end: 86_400, allDay: true),
            event("past", title: "Past", start: 600, end: 900),
            event("current", title: "Current", start: 700, end: 1_100)
        ]

        let sections = EventListSections.build(holidays: [holiday], events: events, now: now)

        XCTAssertEqual(sections.rowOrderIDs, [
            "holiday:2026-02-17:春节",
            "allday:all-day",
            "past:past",
            "upcoming:current",
            "upcoming:late"
        ])
    }

    func testWorkdayHolidayUsesTypeLabel() {
        let workday = HolidayDetailEntry(
            day: PublicCalendarDay(date: "2026-02-08", type: "workday", name: nil, isImportant: false),
            colorId: "stone",
            sourceId: "cn",
            sourceName: "中国大陆",
            isRemote: false
        )

        XCTAssertEqual(workday.displayTitle, L("调休上班"))
        XCTAssertEqual(workday.typeLabel, L("调休上班"))
        XCTAssertTrue(workday.displaySubtitle.contains(L("中国大陆")))
    }

    private func event(_ id: String, title: String, start: TimeInterval, end: TimeInterval, allDay: Bool = false) -> CalendarEvent {
        CalendarEvent(
            id: id,
            externalId: nil,
            title: title,
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
