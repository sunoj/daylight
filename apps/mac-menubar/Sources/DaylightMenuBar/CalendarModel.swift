// Calendar grid model for the native menu bar popover.
// Exports: LocalDate, CalendarDay, CalendarWeekRule, CalendarModel
// Deps: Foundation Calendar and DateComponents

import Foundation

struct LocalDate: Codable, Hashable, CustomStringConvertible {
    let year: Int
    let month: Int
    let day: Int

    var noonDate: Date {
        noonDate(using: Calendar(identifier: .gregorian))
    }

    var key: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    var description: String {
        key
    }

    func noonDate(using calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: 12
        )) ?? Date()
    }
}

struct CalendarDay: Hashable {
    let date: LocalDate
    let isToday: Bool
    let isOutsideMonth: Bool
}

enum CalendarWeekRule: String, CaseIterable, Codable {
    case iso8601
    case us
    case arabic
    case hebrew

    var firstWeekday: Int {
        switch self {
        case .iso8601: return 2
        case .us, .hebrew: return 1
        case .arabic: return 7
        }
    }

    var minimumDaysInFirstWeek: Int {
        self == .iso8601 ? 4 : 1
    }

    /// Column order as weekday indices (0 = Sunday), rotated to the rule's
    /// first weekday. Weekend detection keys off these, not label text.
    var weekdayIndices: [Int] {
        let start = firstWeekday - 1
        return (0..<7).map { (start + $0) % 7 }
    }

    var weekdayLabels: [String] {
        weekdayIndices.map { Loc.weekdayShort($0) }
    }

    static let monthLabels = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ]
}

final class CalendarModel {
    private var calendar: Calendar

    init(calendar: Calendar = Calendar(identifier: .gregorian)) {
        self.calendar = calendar
        self.calendar.timeZone = .current
    }

    func today() -> LocalDate {
        localDate(from: Date())
    }

    func monthGrid(
        year: Int,
        month: Int,
        today: LocalDate,
        weekRule: CalendarWeekRule = .iso8601
    ) -> [CalendarDay] {
        let first = date(from: LocalDate(year: year, month: month, day: 1))
        let weekday = calendar.component(.weekday, from: first)
        let offset = (weekday - weekRule.firstWeekday + 7) % 7
        guard let start = calendar.date(byAdding: .day, value: -offset, to: first) else {
            return []
        }

        return (0..<42).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else {
                return nil
            }
            let local = localDate(from: date)
            return CalendarDay(
                date: local,
                isToday: local == today,
                isOutsideMonth: local.month != month
            )
        }
    }

    func addingMonths(to date: LocalDate, value: Int) -> LocalDate {
        let source = self.date(from: LocalDate(year: date.year, month: date.month, day: 1))
        let next = calendar.date(byAdding: .month, value: value, to: source) ?? source
        return localDate(from: next)
    }

    func addingDays(to date: LocalDate, value: Int) -> LocalDate {
        let source = self.date(from: date)
        let next = calendar.date(byAdding: .day, value: value, to: source) ?? source
        return localDate(from: next)
    }

    func weekNumber(for date: LocalDate, weekRule: CalendarWeekRule) -> Int {
        var ruleCalendar = calendar
        ruleCalendar.firstWeekday = weekRule.firstWeekday
        ruleCalendar.minimumDaysInFirstWeek = weekRule.minimumDaysInFirstWeek
        return ruleCalendar.component(.weekOfYear, from: self.date(from: date))
    }

    private func localDate(from date: Date) -> LocalDate {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return LocalDate(
            year: parts.year ?? 1970,
            month: parts.month ?? 1,
            day: parts.day ?? 1
        )
    }

    private func date(from localDate: LocalDate) -> Date {
        calendar.date(from: DateComponents(
            year: localDate.year,
            month: localDate.month,
            day: localDate.day
        )) ?? Date(timeIntervalSince1970: 0)
    }
}
