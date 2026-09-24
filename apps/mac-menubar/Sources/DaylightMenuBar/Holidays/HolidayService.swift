// Fetches and parses an iCal (.ics) holiday feed into public calendar days.
// Exports: HolidaySource, HolidayService
// Deps: Foundation, DaylightStore

import Foundation

struct HolidaySource {
    let id: String
    let name: String
    let detail: String
    let count: HolidaySourceCount
    let url: String?
}

enum HolidaySourceCount {
    case daysPerYear(Int)
    case days(Int)
    case unknown
    case none
}

final class HolidayService {
    // Prefer official feeds; only mainland China lacks an official iCal, so it
    // uses our own feed (apps/holidays-ical on Cloudflare Pages — see its README;
    // change the base if you attach a custom domain).
    static let feedBase = "https://holidays.mings.work"

    static let presets: [HolidaySource] = [
        HolidaySource(id: "cn", name: "中国大陆", detail: "国务院办公厅 · 官方公告", count: .daysPerYear(13),
                      url: "\(feedBase)/cn.ics?v=2"),
        HolidaySource(id: "hk", name: "中国香港特别行政区", detail: "GovHK 官方日历", count: .days(17),
                      url: "https://www.1823.gov.hk/common/ical/tc.ics"),
        HolidaySource(id: "tw", name: "中国台湾", detail: "行政院人事行政总处", count: .unknown, url: nil),
        HolidaySource(id: "th", name: "泰国", detail: "officeholidays.com", count: .unknown,
                      url: "https://www.officeholidays.com/ics/thailand"),
        HolidaySource(id: "custom", name: "自定义 iCal 链接", detail: "粘贴任意 .ics 订阅地址", count: .none, url: nil)
    ]

    private let store: DaylightStore

    init(store: DaylightStore) {
        self.store = store
    }

    static func preset(_ id: String) -> HolidaySource? {
        presets.first { $0.id == id }
    }

    /// Resolves the effective URL for the given source id and custom string.
    func resolvedURL(source: String, customURL: String) -> URL? {
        if source == "custom" {
            return URL(string: customURL.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return HolidayService.preset(source)?.url.flatMap(URL.init(string:))
    }

    /// Fetches the feed, parses it, and replaces the stored public days.
    /// Completion returns the number of holiday days imported, or an error.
    func subscribe(source: String, customURL: String, completion: @escaping (Result<Int, Error>) -> Void) {
        guard let url = resolvedURL(source: source, customURL: customURL) else {
            completion(.failure(HolidayError.invalidURL))
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error { return DispatchQueue.main.async { completion(.failure(error)) } }
            guard let data, let text = String(data: data, encoding: .utf8) else {
                return DispatchQueue.main.async { completion(.failure(HolidayError.emptyFeed)) }
            }
            let days = HolidayService.parse(ics: text)
            DispatchQueue.main.async {
                self.store.replaceHolidayDays(days, for: "legacy-\(source)")
                completion(days.isEmpty ? .failure(HolidayError.emptyFeed) : .success(days.count))
            }
        }.resume()
    }

    func subscribe(subscriptions: [HolidaySubscription], completion: @escaping ([HolidaySubscriptionFetch]) -> Void) {
        let enabled = subscriptions.filter(\.enabled)
        guard !enabled.isEmpty else {
            completion([])
            return
        }
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "daylight.holiday.subscribe.results")
        var results: [HolidaySubscriptionFetch] = []
        for subscription in enabled {
            guard let url = resolvedURL(source: subscription.sourceId, customURL: subscription.customURL) else {
                queue.sync {
                    results.append(HolidaySubscriptionFetch(subscription: subscription, result: .failure(HolidayError.invalidURL)))
                }
                continue
            }
            group.enter()
            fetch(url: url) { result in
                queue.async {
                    switch result {
                    case let .success(feed):
                        var resolved = subscription
                        if subscription.sourceId == "custom" {
                            resolved.name = HolidayService.resolvedCustomName(
                                subscription: subscription,
                                calendarName: feed.name,
                                url: url
                            )
                        }
                        results.append(HolidaySubscriptionFetch(subscription: resolved, result: .success(feed.days)))
                    case let .failure(error):
                        results.append(HolidaySubscriptionFetch(subscription: subscription, result: .failure(error)))
                    }
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) {
            let ordered = enabled.compactMap { subscription in
                results.first { $0.subscription.id == subscription.id }
            }
            for item in ordered {
                if case let .success(days) = item.result {
                    self.store.replaceHolidayDays(days, for: item.subscription.id)
                }
            }
            self.persistResolvedCustomSubscriptions(ordered)
            completion(ordered)
        }
    }

    /// Minimal VEVENT parser: expands each event's DTSTART…DTEND into day marks.
    /// Operates on unfolded lines (RFC 5545 folds long lines, e.g. the GovHK
    /// feed) and unescapes TEXT values, matching the shared parser in
    /// packages/sync/src/holiday-ical.ts.
    static func parse(ics: String) -> [PublicCalendarDay] {
        var days: [PublicCalendarDay] = []
        var eventNames: [String?] = []
        var start: String?, end: String?, summary: String?
        var type = "holiday"
        for line in unfoldedLines(ics) {
            if line.hasPrefix("BEGIN:VEVENT") { start = nil; end = nil; summary = nil; type = "holiday" }
            else if propertyName(in: line) == "DTSTART" { start = dateValue(line) }
            else if propertyName(in: line) == "DTEND" { end = dateValue(line) }
            else if propertyName(in: line) == "SUMMARY" { summary = unescapeText(propertyValue(in: line)) }
            else if propertyName(in: line) == "X-DAYLIGHT-DAY-TYPE" {
                let value = propertyValue(in: line).trimmingCharacters(in: .whitespaces).lowercased()
                type = ["workday", "observance"].contains(value) ? value : "holiday"
            }
            else if line.hasPrefix("END:VEVENT"), let start {
                let suffix = "（调休上班）"
                let name = type == "workday" && summary?.hasSuffix(suffix) == true
                    ? summary.map { String($0.dropLast(suffix.count)) } : summary
                let expanded = expand(start: start, end: end, name: name, type: type)
                if !expanded.isEmpty {
                    eventNames.append(summary)
                    days.append(contentsOf: expanded)
                }
            }
        }
        return stripSharedFeedPrefix(from: days, eventNames: eventNames)
    }

    static func parseCalendarName(ics: String) -> String? {
        for line in unfoldedLines(ics) {
            guard propertyName(in: line) == "X-WR-CALNAME" else { continue }
            let name = unescapeText(propertyValue(in: line)).trimmingCharacters(in: .whitespacesAndNewlines)
            return name.isEmpty ? nil : name
        }
        return nil
    }

    static func resolvedCustomName(subscription: HolidaySubscription, calendarName: String?, url: URL?) -> String {
        let typed = subscription.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !typed.isEmpty { return typed }
        let imported = calendarName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !imported.isEmpty { return imported }
        let host = url?.host?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return host.isEmpty ? "自定义 iCal 链接" : host
    }

    static func stripSharedFeedPrefix(from days: [PublicCalendarDay], eventNames: [String?]) -> [PublicCalendarDay] {
        guard eventNames.count >= 2,
              let firstName = eventNames.first ?? nil,
              let range = firstName.range(of: ": ") else { return days }
        let prefix = String(firstName[..<range.upperBound])
        guard eventNames.allSatisfy({ name in
            guard let name, name.hasPrefix(prefix) else { return false }
            return !name.dropFirst(prefix.count).isEmpty
        }) else { return days }
        return days.map { day in
            guard let name = day.name, name.hasPrefix(prefix) else { return day }
            var stripped = day
            stripped.name = String(name.dropFirst(prefix.count))
            return stripped
        }
    }

    private func fetch(url: URL, completion: @escaping (Result<(name: String?, days: [PublicCalendarDay]), Error>) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error { return completion(.failure(error)) }
            guard let data, let text = String(data: data, encoding: .utf8) else {
                return completion(.failure(HolidayError.emptyFeed))
            }
            let days = HolidayService.parse(ics: text)
            completion(days.isEmpty ? .failure(HolidayError.emptyFeed) : .success((HolidayService.parseCalendarName(ics: text), days)))
        }.resume()
    }

    private func persistResolvedCustomSubscriptions(_ fetches: [HolidaySubscriptionFetch]) {
        var settings = store.settings()
        var changed = false
        for fetch in fetches where fetch.subscription.sourceId == "custom" {
            guard case .success = fetch.result,
                  let index = settings.holidaySubscriptions.firstIndex(where: { $0.id == fetch.subscription.id }) else { continue }
            settings.holidaySubscriptions[index] = fetch.subscription
            changed = true
        }
        if changed { store.saveSettings(settings) }
    }

    private static func unfoldedLines(_ ics: String) -> [String] {
        var lines: [String] = []
        for rawLine in ics.replacingOccurrences(of: "\r\n", with: "\n").split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(rawLine)
            if (line.hasPrefix(" ") || line.hasPrefix("\t")), !lines.isEmpty {
                lines[lines.count - 1] += line.dropFirst()
            } else {
                lines.append(line)
            }
        }
        return lines
    }

    private static func propertyName(in line: String) -> String {
        let end = line.firstIndex { $0 == ":" || $0 == ";" } ?? line.endIndex
        return String(line[..<end]).uppercased()
    }

    private static func propertyValue(in line: String) -> String {
        guard let colon = line.firstIndex(of: ":") else { return "" }
        return String(line[line.index(after: colon)...])
    }

    // RFC 5545 TEXT unescaping: \\ \; \, \n (holiday names fold newlines to a space).
    private static func unescapeText(_ value: String) -> String {
        var result = ""
        var escaped = false
        for char in value {
            if escaped {
                result.append(char == "n" || char == "N" ? " " : String(char))
                escaped = false
            } else if char == "\\" {
                escaped = true
            } else {
                result.append(char)
            }
        }
        return result
    }

    private static func dateValue(_ line: String) -> String? {
        let digits = propertyValue(in: line).prefix(8)
        return digits.count == 8 && digits.allSatisfy(\.isNumber) ? String(digits) : nil
    }

    private static func expand(start: String, end: String?, name: String?, type: String) -> [PublicCalendarDay] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        guard let startDate = date(start, calendar) else { return [] }
        // A missing or malformed DTEND (including DTEND <= DTSTART) still marks
        // the start day instead of dropping the event.
        let parsedEnd = end.flatMap { date($0, calendar) }
        let endExclusive = (parsedEnd.map { $0 > startDate } == true ? parsedEnd : nil)
            ?? calendar.date(byAdding: .day, value: 1, to: startDate)
        var result: [PublicCalendarDay] = []
        var cursor = startDate
        while cursor < (endExclusive ?? startDate.addingTimeInterval(1)) {
            let parts = calendar.dateComponents([.year, .month, .day], from: cursor)
            let key = String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
            result.append(PublicCalendarDay(date: key, type: type, name: name, isImportant: true))
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
            if result.count > 366 { break }
        }
        return result
    }

    private static func date(_ yyyymmdd: String, _ calendar: Calendar) -> Date? {
        guard yyyymmdd.count == 8,
              let year = Int(yyyymmdd.prefix(4)),
              let month = Int(yyyymmdd.dropFirst(4).prefix(2)),
              let day = Int(yyyymmdd.dropFirst(6).prefix(2)) else { return nil }
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
    }
}

enum HolidayError: Error {
    case invalidURL
    case emptyFeed
}

struct HolidaySubscriptionFetch {
    let subscription: HolidaySubscription
    let result: Result<[PublicCalendarDay], Error>
}
