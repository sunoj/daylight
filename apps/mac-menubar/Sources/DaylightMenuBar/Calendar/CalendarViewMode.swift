// Calendar navigation modes for month, year, decade, and century views.
// Exports: CalendarViewMode, CalendarPeriod
// Deps: CalendarModel LocalDate

import Foundation

enum CalendarViewMode: String, CaseIterable {
    case month = "Month"
    case year = "Year"
    case decade = "Decade"
    case century = "Century"
}

struct CalendarPeriod: Equatable {
    let title: String
    let previousStepMonths: Int
    let nextStepMonths: Int

    static func period(for date: LocalDate, mode: CalendarViewMode) -> CalendarPeriod {
        // Titles go through Loc.displayYear so Thai shows Buddhist Era years;
        // grouping and stepping stay Gregorian.
        switch mode {
        case .month:
            return CalendarPeriod(title: "\(Loc.displayYear(date.year)).\(String(format: "%02d", date.month))", previousStepMonths: -1, nextStepMonths: 1)
        case .year:
            return CalendarPeriod(title: String(Loc.displayYear(date.year)), previousStepMonths: -12, nextStepMonths: 12)
        case .decade:
            let start = (date.year / 10) * 10
            return CalendarPeriod(title: "\(Loc.displayYear(start))-\(Loc.displayYear(start + 9))", previousStepMonths: -120, nextStepMonths: 120)
        case .century:
            let start = (date.year / 100) * 100
            return CalendarPeriod(title: "\(Loc.displayYear(start))-\(Loc.displayYear(start + 99))", previousStepMonths: -1_200, nextStepMonths: 1_200)
        }
    }
}
