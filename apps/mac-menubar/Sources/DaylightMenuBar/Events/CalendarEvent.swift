// Value type used to render one system calendar event.
// Exports: CalendarEvent
// Deps: Foundation, AppKit, Palette

import AppKit
import Foundation

struct CalendarEvent: Hashable {
    let id: String
    let externalId: String?
    let title: String
    let start: Date
    let end: Date
    let isAllDay: Bool
    let calendarId: String
    let calendarTitle: String
    let colorHex: String
    let location: String?
    let videoURL: URL?

    var color: NSColor {
        guard colorHex.count == 6, let value = Int(colorHex, radix: 16) else { return Palette.ink2 }
        return Palette.rgb(value)
    }

    func timeRangeText(use24Hour: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = use24Hour ? "HH:mm" : "h:mm a"
        return "\(formatter.string(from: start))–\(formatter.string(from: end))"
    }
}
