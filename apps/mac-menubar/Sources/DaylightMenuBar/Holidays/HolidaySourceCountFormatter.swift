// Formats structured holiday preset day counts for display.
// Exports: HolidaySourceCountFormatter
// Deps: Localization, HolidayService

enum HolidaySourceCountFormatter {
    static func string(for count: HolidaySourceCount) -> String {
        switch count {
        case let .daysPerYear(value):
            switch Loc.language {
            case .zh, .zhHant: return "\(value) 天 / 年"
            case .en: return "\(value) days / year"
            case .th: return "\(value) วัน / ปี"
            }
        case let .days(value):
            switch Loc.language {
            case .zh, .zhHant: return "\(value) 天"
            case .en: return "\(value) days"
            case .th: return "\(value) วัน"
            }
        case .unknown:
            return "—"
        case .none:
            return ""
        }
    }
}
