// Pure sorting and grouping for a selected day's event list.
// Exports: EventListSections
// Deps: Foundation, CalendarEvent, HolidayDetailEntry

import Foundation

struct EventListSections {
    let holidays: [HolidayDetailEntry]
    let allDay: [CalendarEvent]
    let past: [CalendarEvent]
    let upcoming: [CalendarEvent]

    var isEmpty: Bool {
        holidays.isEmpty && allDay.isEmpty && past.isEmpty && upcoming.isEmpty
    }

    /// Stable row order for tests: subscribed holidays, then all-day, past, upcoming.
    var rowOrderIDs: [String] {
        holidays.map { "holiday:\($0.day.date):\($0.displayTitle)" } +
            allDay.map { "allday:\($0.id)" } +
            past.map { "past:\($0.id)" } +
            upcoming.map { "upcoming:\($0.id)" }
    }

    /// Separates subscribed holidays first, then all-day events, then timed past/upcoming.
    static func build(
        holidays: [HolidayDetailEntry] = [],
        events: [CalendarEvent],
        now: Date
    ) -> EventListSections {
        let allDay = events.filter(\.isAllDay).sorted(by: titleOrder)
        let timed = events.filter { !$0.isAllDay }
        let past = timed.filter { $0.end < now }.sorted(by: startOrder)
        let upcoming = timed.filter { $0.end >= now }.sorted(by: startOrder)
        return EventListSections(holidays: holidays, allDay: allDay, past: past, upcoming: upcoming)
    }

    private static func titleOrder(_ lhs: CalendarEvent, _ rhs: CalendarEvent) -> Bool {
        lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
    }

    private static func startOrder(_ lhs: CalendarEvent, _ rhs: CalendarEvent) -> Bool {
        if lhs.start != rhs.start { return lhs.start < rhs.start }
        return titleOrder(lhs, rhs)
    }
}
