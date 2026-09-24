// Read-only bridge from EventKit events to CalendarEvent values.
// Exports: SystemCalendarAuthorization, SystemCalendarService
// Deps: EventKit, AppKit, Foundation, CalendarEvent, LocalDate, VideoLinkDetector

import AppKit
import EventKit
import Foundation

enum SystemCalendarAuthorization {
    case notDetermined
    case authorized
    case denied
    case restricted
}

final class SystemCalendarService {
    static let shared = SystemCalendarService()

    var onChange: (() -> Void)?

    private let eventStore = EKEventStore()
    private var cachedKey: CacheKey?
    private var cachedEvents: [CalendarEvent] = []

    init() {
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            self.cachedKey = nil
            self.cachedEvents = []
            DispatchQueue.main.async { [weak self] in
                self?.onChange?()
            }
        }
    }

    var authorization: SystemCalendarAuthorization {
        if #available(macOS 14.0, *) {
            switch EKEventStore.authorizationStatus(for: .event) {
            case .fullAccess, .writeOnly: return .authorized
            case .denied: return .denied
            case .restricted: return .restricted
            case .notDetermined: return .notDetermined
            @unknown default: return .denied
            }
        }

        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized, .fullAccess, .writeOnly: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .denied
        }
    }

    func requestAccess(_ completion: @escaping (Bool) -> Void) {
        let finish: (Bool) -> Void = { granted in
            DispatchQueue.main.async { completion(granted) }
        }
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { granted, _ in finish(granted) }
        } else {
            eventStore.requestAccess(to: .event) { granted, _ in finish(granted) }
        }
    }

    func calendarCount() -> Int {
        calendars().count
    }

    func calendars() -> [SystemCalendarInfo] {
        guard isAuthorized else { return [] }
        return eventStore.calendars(for: .event)
            .map(makeCalendarInfo)
            .sorted {
                if $0.sourceTitle != $1.sourceTitle { return $0.sourceTitle < $1.sourceTitle }
                return $0.title < $1.title
            }
    }

    func calendarCounts(hiddenIds: [String]) -> (visible: Int, total: Int) {
        let all = calendars()
        let visible = SystemCalendarVisibility.visibleCount(allIds: all.map(\.id), hiddenIds: hiddenIds)
        return (visible, all.count)
    }

    /// Returns events overlapping the half-open range, using one cached range at a time.
    func events(from: Date, to: Date, hiddenCalendarIds: [String] = []) -> [CalendarEvent] {
        guard isAuthorized, from < to else { return [] }
        let hidden = Set(hiddenCalendarIds)
        let key = CacheKey(from: from, to: to, hiddenIds: hidden)
        if cachedKey == key { return cachedEvents }

        let calendars = eventStore.calendars(for: .event).filter { !hidden.contains($0.calendarIdentifier) }
        guard !calendars.isEmpty else {
            cachedKey = key
            cachedEvents = []
            return []
        }

        let predicate = eventStore.predicateForEvents(withStart: from, end: to, calendars: calendars)
        let values = eventStore.events(matching: predicate)
            .filter { $0.startDate < to && $0.endDate > from }
            .sorted { $0.startDate < $1.startDate }
            .map(makeEvent)
        cachedKey = key
        cachedEvents = values
        return values
    }

    func events(on date: LocalDate, hiddenCalendarIds: [String] = []) -> [CalendarEvent] {
        let start = startOfDay(date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        return events(from: start, to: end, hiddenCalendarIds: hiddenCalendarIds)
    }

    /// Expands overlapping events across every covered local calendar day.
    func eventsByDay(from: LocalDate, to: LocalDate, hiddenCalendarIds: [String] = []) -> [String: [CalendarEvent]] {
        guard from.key <= to.key else { return [:] }
        let start = startOfDay(from)
        let end = calendar.date(byAdding: .day, value: 1, to: startOfDay(to)) ?? start
        let values = events(from: start, to: end, hiddenCalendarIds: hiddenCalendarIds)
        var result: [String: [CalendarEvent]] = [:]
        var date = from
        while true {
            let dayStart = startOfDay(date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            result[date.key] = values.filter { $0.start < dayEnd && $0.end > dayStart }
            if date == to { break }
            date = addingDay(to: date)
        }
        return result
    }

    func openInCalendar(_ event: CalendarEvent) {
        guard let externalId = event.externalId, let url = calendarURL(for: event, externalId: externalId),
              NSWorkspace.shared.open(url) else {
            openCalendarApp()
            return
        }
    }

    private var isAuthorized: Bool { authorization == .authorized }

    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = .current
        return value
    }

    private func startOfDay(_ date: LocalDate) -> Date {
        calendar.date(from: DateComponents(year: date.year, month: date.month, day: date.day)) ?? date.noonDate
    }

    private func addingDay(to date: LocalDate) -> LocalDate {
        let next = calendar.date(byAdding: .day, value: 1, to: startOfDay(date)) ?? startOfDay(date)
        let parts = calendar.dateComponents([.year, .month, .day], from: next)
        return LocalDate(year: parts.year ?? date.year, month: parts.month ?? date.month, day: parts.day ?? date.day)
    }

    private func makeCalendarInfo(_ calendar: EKCalendar) -> SystemCalendarInfo {
        SystemCalendarInfo(
            id: calendar.calendarIdentifier,
            title: calendar.title,
            colorHex: colorHex(calendar.color),
            sourceTitle: calendar.source.title
        )
    }

    private func makeEvent(_ event: EKEvent) -> CalendarEvent {
        let location = event.location?.isEmpty == false ? event.location : nil
        return CalendarEvent(
            id: event.eventIdentifier ?? "",
            externalId: event.calendarItemExternalIdentifier,
            title: event.title ?? "",
            start: event.startDate,
            end: event.endDate,
            isAllDay: event.isAllDay,
            calendarId: event.calendar.calendarIdentifier,
            calendarTitle: event.calendar.title,
            colorHex: colorHex(event.calendar.color),
            location: location,
            videoURL: VideoLinkDetector.detect(url: event.url, notes: event.notes, location: location)
        )
    }

    private func colorHex(_ color: NSColor) -> String {
        let value = color.usingColorSpace(.sRGB) ?? color
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        value.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(format: "%02X%02X%02X", Int((red * 255).rounded()), Int((green * 255).rounded()), Int((blue * 255).rounded()))
    }

    private func calendarURL(for event: CalendarEvent, externalId: String) -> URL? {
        let date = event.isAllDay ? utcMidnight(for: event.start) : event.start
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        let stamp = formatter.string(from: date)
        let encodedId = externalId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? externalId
        return URL(string: "ical://ekevent/\(stamp)/\(encodedId)?method=show&options=more")
    }

    private func utcMidnight(for date: Date) -> Date {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        return utc.date(from: DateComponents(year: parts.year, month: parts.month, day: parts.day)) ?? date
    }

    private func openCalendarApp() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal") else { return }
        _ = NSWorkspace.shared.open(url)
    }

    private struct CacheKey: Hashable {
        let from: Date
        let to: Date
        let hiddenIds: Set<String>
    }
}
