// Compact six-week calendar grid for Luna mode.
// Exports: LunaMonthGridView
// Deps: AppKit, CalendarModel, CalendarDayTitleFormatter, Components, DesignSystem

import AppKit

final class LunaMonthGridView: NSView {
    init(
        store: DaylightStore,
        calendarModel: CalendarModel,
        lunarCalendar: LunarCalendar,
        year: Int,
        month: Int,
        selectedDate: LocalDate,
        settings: UserSettings,
        eventsByDay: [String: [CalendarEvent]],
        onSelectDate: @escaping (LocalDate) -> Void
    ) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        render(
            store: store,
            calendarModel: calendarModel,
            lunarCalendar: lunarCalendar,
            year: year,
            month: month,
            selectedDate: selectedDate,
            settings: settings,
            eventsByDay: eventsByDay,
            onSelectDate: onSelectDate
        )
    }

    required init?(coder: NSCoder) { nil }

    private func render(
        store: DaylightStore,
        calendarModel: CalendarModel,
        lunarCalendar: LunarCalendar,
        year: Int,
        month: Int,
        selectedDate: LocalDate,
        settings: UserSettings,
        eventsByDay: [String: [CalendarEvent]],
        onSelectDate: @escaping (LocalDate) -> Void
    ) {
        let days = calendarModel.monthGrid(year: year, month: month, today: calendarModel.today(), weekRule: settings.weekRule)
        var titleSettings = settings
        titleSettings.showLunarDate = settings.lunaShowLunarDate
        let formatter = CalendarDayTitleFormatter(store: store, lunarCalendar: lunarCalendar)
        let titles = days.map { formatter.titleParts(for: $0, settings: titleSettings) }
        let showsSubtitle = settings.lunaShowLunarDate && titles.contains { $0.secondary != nil }

        weekdayLabels = settings.weekRule.weekdayLabels.enumerated().map { index, label in
            weekdayLabel(label.uppercased(), weekend: isWeekend(index: index, rule: settings.weekRule))
        }
        cells = days.enumerated().map { index, day in
            LunaDateCell(
                day: day,
                title: titles[index],
                events: eventsByDay[day.date.key] ?? [],
                selectedDate: selectedDate,
                showsSubtitle: showsSubtitle,
                onSelectDate: onSelectDate
            )
        }
        cellHeight = showsSubtitle ? Metrics.lunaCellHeightTall : Metrics.lunaCellHeight
        for view in weekdayLabels + cells {
            view.translatesAutoresizingMaskIntoConstraints = true
            addSubview(view)
        }
    }

    // Laid out by frame: the former weekday row plus six equal-width row stacks
    // were seven NSStackViews re-solved by Auto Layout on every render.
    private static let insets = NSEdgeInsets(top: 0, left: 14, bottom: 10, right: 14)
    private var weekdayLabels: [NSView] = []
    private var cells: [NSView] = []
    private var cellHeight: CGFloat = Metrics.lunaCellHeight

    override var isFlipped: Bool { true }

    private var weekdayHeight: CGFloat {
        weekdayLabels.map(\.intrinsicContentSize.height).max() ?? 0
    }

    override var intrinsicContentSize: NSSize {
        let rows = CGFloat(cells.count / 7)
        let height = Self.insets.top + weekdayHeight + Metrics.gridGap
            + rows * cellHeight + max(rows - 1, 0) * Metrics.gridGap + Self.insets.bottom
        return NSSize(width: NSView.noIntrinsicMetric, height: height)
    }

    override func layout() {
        super.layout()
        let gap = Metrics.gridGap
        let columnWidth = (bounds.width - Self.insets.left - Self.insets.right - 6 * gap) / 7
        let x = { (column: Int) in Self.insets.left + CGFloat(column) * (columnWidth + gap) }
        let labelHeight = weekdayHeight
        for (column, label) in weekdayLabels.enumerated() {
            label.frame = aligned(NSRect(x: x(column), y: Self.insets.top, width: columnWidth, height: labelHeight))
        }
        var y = Self.insets.top + labelHeight + gap
        for row in 0..<(cells.count / 7) {
            for column in 0..<7 {
                cells[row * 7 + column].frame = aligned(NSRect(x: x(column), y: y, width: columnWidth, height: cellHeight))
            }
            y += cellHeight + gap
        }
    }

    private func aligned(_ rect: NSRect) -> NSRect {
        backingAlignedRect(rect, options: .alignAllEdgesNearest)
    }

    private func weekdayLabel(_ text: String, weekend: Bool) -> NSView {
        UI.label(text, font: Typography.mono(10, .medium), color: weekend ? Palette.ink4 : Palette.ink3, align: .center, tracking: 0.5)
    }

    private func isWeekend(index: Int, rule: CalendarWeekRule) -> Bool {
        let weekday = rule.weekdayIndices[index]
        return weekday == 0 || weekday == 6
    }
}
