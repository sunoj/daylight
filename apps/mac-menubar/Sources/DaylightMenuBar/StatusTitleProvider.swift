// Resolves the ordered menu bar status segments from settings.
// Exports: StatusSegment, StatusSegmentKind, StatusTitleProvider
// Deps: Foundation Date, CalendarModel, LunarCalendar, MoonPhaseCalculator

import Foundation

/// The known status bar segment kinds, in the order shown in the editor.
enum StatusSegmentKind: String, CaseIterable {
    case moon
    case dateBox
    case gregorian
    case lunar
    case weekday
    case time

    var displayName: String {
        switch self {
        case .moon: return L("月相图标")
        case .dateBox: return L("日期方块")
        case .gregorian: return L("公历日")
        case .lunar: return L("农历日")
        case .weekday: return L("星期")
        case .time: return L("时间")
        }
    }
}

/// A resolved segment ready to render: an icon carries its data, text carries a string.
enum StatusSegment: Equatable {
    case moon(fraction: Double, waxing: Bool)
    case dateBox(String)
    case text(String)
}

final class StatusTitleProvider {
    private let calendar: Calendar
    private let lunarCalendar: LunarCalendar
    private let moonPhase: MoonPhaseCalculator

    init(
        calendar: Calendar = .current,
        lunarCalendar: LunarCalendar = LunarCalendar(),
        moonPhase: MoonPhaseCalculator = MoonPhaseCalculator()
    ) {
        self.calendar = calendar
        self.lunarCalendar = lunarCalendar
        self.moonPhase = moonPhase
    }

    func segments(today: LocalDate, settings: UserSettings, now: Date = Date()) -> [StatusSegment] {
        settings.statusSegments.compactMap { segment(id: $0, today: today, settings: settings, now: now) }
    }

    private func segment(id: String, today: LocalDate, settings: UserSettings, now: Date) -> StatusSegment? {
        switch StatusSegmentKind(rawValue: id) {
        case .moon:
            return .moon(fraction: moonPhase.illuminatedFraction(for: now), waxing: moonPhase.isWaxing(for: now))
        case .dateBox:
            return .dateBox(String(today.day))
        case .gregorian:
            return .text(String(today.day))
        case .lunar:
            guard let lunar = lunarCalendar.lunarDate(for: today) else { return nil }
            return .text(lunar.dayName)
        case .weekday:
            return .text(weekdayName(for: now))
        case .time:
            return .text(timeString(for: now, use24Hour: settings.statusUse24HourTime))
        case .none:
            return nil
        }
    }

    private func weekdayName(for date: Date) -> String {
        Loc.weekday(calendar.component(.weekday, from: date) - 1)
    }

    private func timeString(for date: Date, use24Hour: Bool) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let hour = parts.hour ?? 0
        let minute = parts.minute ?? 0
        if use24Hour {
            return String(format: "%02d:%02d", hour, minute)
        }
        let suffix = hour < 12 ? "AM" : "PM"
        let hour12 = hour % 12 == 0 ? 12 : hour % 12
        return String(format: "%d:%02d %@", hour12, minute, suffix)
    }
}
