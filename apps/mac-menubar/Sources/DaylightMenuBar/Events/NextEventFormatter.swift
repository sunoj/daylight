// Pure selection and relative-time formatting for the agenda footer.
// Exports: NextEventFormatter
// Deps: Foundation, CalendarEvent, Loc

import Foundation

enum NextEventFormatter {
    /// Finds the soonest timed event that has not ended yet.
    static func next(in events: [CalendarEvent], now: Date) -> CalendarEvent? {
        events
            .filter { !$0.isAllDay && $0.end >= now }
            .sorted {
                if $0.start != $1.start { return $0.start < $1.start }
                return $0.title.localizedStandardCompare($1.title) == .orderedAscending
            }
            .first
    }

    /// Formats only the first 24 hours so the footer never becomes a long-range reminder.
    static func relative(to start: Date, from now: Date) -> String? {
        let seconds = start.timeIntervalSince(now)
        guard seconds <= 24 * 60 * 60 else { return nil }
        if seconds <= 0 { return L("现在") }

        if seconds < 60 * 60 {
            let minutes = Int(seconds / 60)
            return relativeValue(minutes, unit: "分钟")
        }

        let hours = Int(seconds / (60 * 60))
        return relativeValue(hours, unit: "小时")
    }

    private static func relativeValue(_ value: Int, unit: String) -> String {
        if Loc.language == .zh || Loc.language == .zhHant {
            return L("\(value) \(unit)后")
        }
        return "\(L("还有")) \(value) \(L(unit))"
    }
}
