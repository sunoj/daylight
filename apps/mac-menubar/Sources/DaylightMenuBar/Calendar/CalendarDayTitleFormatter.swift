// Pure formatter for calendar day cell contents.
// Exports: CalendarDayTitle, CalendarDayTitleFormatter
// Deps: DaylightStore, HolidayDetailEntry, LunarCalendar, UserSettings

struct CalendarDayTitle: Equatable {
    let primary: String
    let secondary: String?
    let isSolarTerm: Bool
    let holidayColorIds: [String]
    let holidayTooltip: String?
    var isWorkday: Bool = false

    init(primary: String, secondary: String?, isSolarTerm: Bool, holidayColorIds: [String], holidayTooltip: String? = nil) {
        self.primary = primary
        self.secondary = secondary
        self.isSolarTerm = isSolarTerm
        self.holidayColorIds = holidayColorIds
        self.holidayTooltip = holidayTooltip
    }
}

struct CalendarDayTitleFormatter {
    private let store: DaylightStore
    private let lunarCalendar: LunarCalendar

    init(store: DaylightStore, lunarCalendar: LunarCalendar) {
        self.store = store
        self.lunarCalendar = lunarCalendar
    }

    func titleParts(for day: CalendarDay, settings: UserSettings) -> CalendarDayTitle {
        let hits = store.holidayHits(for: day.date)
        var title = baseTitleParts(for: day, settings: settings, holidayHits: hits)
        title.isWorkday = hits.contains { $0.day.type == "workday" }
            || (hits.isEmpty && store.publicDays().contains { $0.date == day.date.key && $0.type == "workday" })
        return title
    }

    private func baseTitleParts(for day: CalendarDay, settings: UserSettings, holidayHits: [(subscription: HolidaySubscription, day: PublicCalendarDay)]) -> CalendarDayTitle {
        let primary = String(day.date.day)
        let publicDay = holidayHits.first?.day ?? store.publicDays().first { $0.date == day.date.key }
        let holidayColorIds = holidayHits.map(\.subscription.colorId)
        let holidayTooltip = holidayTooltip(for: day.date, holidayHits: holidayHits)
        if let publicName = publicDay?.name {
            return CalendarDayTitle(primary: primary, secondary: L(publicName), isSolarTerm: false, holidayColorIds: holidayColorIds, holidayTooltip: holidayTooltip)
        }
        guard settings.showLunarDate, let lunar = lunarCalendar.lunarDate(for: day.date) else {
            return CalendarDayTitle(primary: primary, secondary: nil, isSolarTerm: false, holidayColorIds: holidayColorIds, holidayTooltip: holidayTooltip)
        }
        if let term = lunar.solarTerm {
            return CalendarDayTitle(primary: primary, secondary: L(term), isSolarTerm: true, holidayColorIds: holidayColorIds, holidayTooltip: holidayTooltip)
        }
        return CalendarDayTitle(primary: primary, secondary: L(lunar.dayName), isSolarTerm: false, holidayColorIds: holidayColorIds, holidayTooltip: holidayTooltip)
    }

    private func holidayTooltip(for date: LocalDate, holidayHits: [(subscription: HolidaySubscription, day: PublicCalendarDay)]) -> String? {
        let lines = HolidayDetailEntries.entries(for: date, store: store, holidayHits: holidayHits).map(holidayTooltipLine)
        return lines.isEmpty ? nil : lines.joined(separator: "\n")
    }

    private func holidayTooltipLine(_ entry: HolidayDetailEntry) -> String {
        let source = L(entry.sourceName)
        guard entry.day.type != "holiday" else { return "\(holidayName(entry.day)) · \(source)" }
        return "\(holidayName(entry.day)) · \(source) · \(holidayTypeName(entry.day.type))"
    }

    private func holidayName(_ day: PublicCalendarDay) -> String {
        let name = day.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? holidayTypeName(day.type) : L(name)
    }

    private func holidayTypeName(_ type: String) -> String {
        switch type {
        case "workday": return L("调休上班")
        case "observance": return L("纪念日")
        default: return L("节假日")
        }
    }
}
