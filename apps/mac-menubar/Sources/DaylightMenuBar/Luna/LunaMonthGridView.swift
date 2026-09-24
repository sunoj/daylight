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

        let content = NSStackView()
        content.orientation = .vertical
        content.spacing = Metrics.gridGap
        content.alignment = .leading
        content.edgeInsets = NSEdgeInsets(top: 0, left: 14, bottom: 10, right: 14)
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor),
            content.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.trailingAnchor.constraint(equalTo: trailingAnchor),
            content.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        let weekdays = NSStackView(views: settings.weekRule.weekdayLabels.enumerated().map { index, label in
            weekdayLabel(label.uppercased(), weekend: isWeekend(index: index, rule: settings.weekRule))
        })
        weekdays.orientation = .horizontal
        weekdays.distribution = .fillEqually
        weekdays.spacing = Metrics.gridGap
        content.addArrangedSubview(weekdays)
        weekdays.widthAnchor.constraint(equalTo: content.widthAnchor).isActive = true

        let grid = NSStackView()
        grid.orientation = .vertical
        grid.spacing = Metrics.gridGap
        grid.alignment = .leading
        content.addArrangedSubview(grid)
        grid.widthAnchor.constraint(equalTo: content.widthAnchor).isActive = true
        for rowIndex in 0..<6 {
            let row = NSStackView()
            row.orientation = .horizontal
            row.distribution = .fillEqually
            row.spacing = Metrics.gridGap
            for column in 0..<7 {
                let index = rowIndex * 7 + column
                let day = days[index]
                row.addArrangedSubview(LunaDateCell(
                    day: day,
                    title: titles[index],
                    events: eventsByDay[day.date.key] ?? [],
                    selectedDate: selectedDate,
                    showsSubtitle: showsSubtitle,
                    onSelectDate: onSelectDate
                ))
            }
            grid.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: grid.widthAnchor).isActive = true
        }
    }

    private func weekdayLabel(_ text: String, weekend: Bool) -> NSView {
        UI.label(text, font: Typography.mono(10, .medium), color: weekend ? Palette.ink4 : Palette.ink3, align: .center, tracking: 0.5)
    }

    private func isWeekend(index: Int, rule: CalendarWeekRule) -> Bool {
        let weekday = rule.weekdayIndices[index]
        return weekday == 0 || weekday == 6
    }
}
