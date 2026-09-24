// Pure logic for choosing popover screen transition styles.
// Exports: PopoverRenderState, ScreenTransition
// Deps: PopoverScreen, CalendarViewMode, LocalDate

import CoreGraphics
import Foundation

struct PopoverRenderState: Equatable {
    let screen: PopoverScreen
    let viewMode: CalendarViewMode
    let visibleMonth: LocalDate
    let selectedDate: LocalDate
}

enum ScreenTransition: Equatable {
    case none
    case fade
    case push(fromTrailing: Bool)
    case zoom(from: CGFloat)

    static func resolve(from previous: PopoverRenderState?, to next: PopoverRenderState) -> ScreenTransition {
        guard let previous else { return .none }
        if previous == next { return .none }

        if previous.screen != next.screen {
            let fromDepth = navigationDepth(previous.screen)
            let toDepth = navigationDepth(next.screen)
            if toDepth > fromDepth { return .push(fromTrailing: true) }
            if toDepth < fromDepth { return .push(fromTrailing: false) }
            return .fade
        }

        if previous.viewMode != next.viewMode {
            return viewModeRank(next.viewMode) > viewModeRank(previous.viewMode)
                ? .zoom(from: 1.06)
                : .zoom(from: 0.94)
        }

        let previousOrdinal = monthOrdinal(previous.visibleMonth)
        let nextOrdinal = monthOrdinal(next.visibleMonth)
        if previousOrdinal != nextOrdinal {
            return .push(fromTrailing: nextOrdinal > previousOrdinal)
        }

        return .none
    }

    private static func navigationDepth(_ screen: PopoverScreen) -> Int {
        switch screen {
        case .calendar, .luna: return 0
        case .settings, .moon, .locationPrompt: return 1
        case .systemCalendar, .statusEditor, .holidays: return 2
        }
    }

    private static func viewModeRank(_ mode: CalendarViewMode) -> Int {
        switch mode {
        case .month: return 0
        case .year: return 1
        case .decade: return 2
        case .century: return 3
        }
    }

    private static func monthOrdinal(_ date: LocalDate) -> Int {
        date.year * 12 + date.month
    }
}
