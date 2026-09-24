// Pure helpers for per-calendar visibility stored as hidden ids.
// Exports: SystemCalendarVisibility
// Deps: Foundation

enum SystemCalendarVisibility {
    static func isVisible(calendarId: String, hiddenIds: [String]) -> Bool {
        !hiddenIds.contains(calendarId)
    }

    static func visibleCount(allIds: [String], hiddenIds: [String]) -> Int {
        let hidden = Set(hiddenIds)
        return allIds.filter { !hidden.contains($0) }.count
    }

    static func toggleVisibility(calendarId: String, hiddenIds: [String]) -> [String] {
        var next = hiddenIds
        if let index = next.firstIndex(of: calendarId) {
            next.remove(at: index)
        } else {
            next.append(calendarId)
        }
        return next
    }
}
