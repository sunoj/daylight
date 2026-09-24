// AppKit month grid for calendar display rules and day subtitles.
// Exports: CalendarMonthView, CalendarMonthViewConfig
// Deps: AppKit, CalendarEvent, CalendarModel, DaylightStore, LunarCalendar, DesignSystem

import AppKit

struct CalendarMonthViewConfig {
    let year: Int
    let month: Int
    let selectedDate: LocalDate
    let settings: UserSettings
    let eventsByDay: [String: [CalendarEvent]]

    init(
        year: Int,
        month: Int,
        selectedDate: LocalDate,
        settings: UserSettings,
        eventsByDay: [String: [CalendarEvent]] = [:]
    ) {
        self.year = year
        self.month = month
        self.selectedDate = selectedDate
        self.settings = settings
        self.eventsByDay = eventsByDay
    }
}

final class CalendarMonthView: NSStackView {
    private let calendarModel: CalendarModel
    private let titleFormatter: CalendarDayTitleFormatter
    private let onSelectDate: (LocalDate) -> Void

    init(
        store: DaylightStore,
        calendarModel: CalendarModel,
        lunarCalendar: LunarCalendar,
        config: CalendarMonthViewConfig,
        onSelectDate: @escaping (LocalDate) -> Void
    ) {
        self.calendarModel = calendarModel
        self.titleFormatter = CalendarDayTitleFormatter(store: store, lunarCalendar: lunarCalendar)
        self.onSelectDate = onSelectDate
        super.init(frame: .zero)
        orientation = .vertical
        spacing = Metrics.gridGap
        render(config)
    }

    required init?(coder: NSCoder) { nil }

    private func render(_ config: CalendarMonthViewConfig) {
        alignment = .leading
        let weekdays = weekdayRow(settings: config.settings)
        let grid = calendarGrid(config)
        addArrangedSubview(weekdays)
        addArrangedSubview(grid)
        weekdays.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        grid.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }

    private func weekdayRow(settings: UserSettings) -> NSView {
        let labels = settings.weekRule.weekdayLabels
        let cells: [NSView] = labels.enumerated().map { index, label in
            weekdayLabel(label.uppercased(), weekend: isWeekendColumn(index: index, rule: settings.weekRule))
        }
        let leading = settings.showWeekNumbers ? weekHeaderColumn() : nil
        return gridRow(leading: leading, cells: cells)
    }

    private func calendarGrid(_ config: CalendarMonthViewConfig) -> NSView {
        let grid = NSStackView()
        grid.orientation = .vertical
        grid.spacing = Metrics.gridGap
        grid.alignment = .leading
        let days = calendarModel.monthGrid(
            year: config.year,
            month: config.month,
            today: calendarModel.today(),
            weekRule: config.settings.weekRule
        )
        let titles = days.map { titleFormatter.titleParts(for: $0, settings: config.settings) }
        // One height for the whole grid: reserve the subtitle line only if any
        // day actually has one (lunar/solar term, or a holiday name even with
        // 农历 off). Otherwise the grid collapses to the compact height.
        let showsSubtitle = titles.contains { $0.secondary != nil }
        for row in 0..<6 {
            let dayRowView = dayRow(row: row, days: days, titles: titles, showsSubtitle: showsSubtitle, config: config)
            grid.addArrangedSubview(dayRowView)
            dayRowView.widthAnchor.constraint(equalTo: grid.widthAnchor).isActive = true
        }
        return grid
    }

    private func dayRow(row: Int, days: [CalendarDay], titles: [CalendarDayTitle], showsSubtitle: Bool, config: CalendarMonthViewConfig) -> NSView {
        let rowDays = (0..<7).map { days[row * 7 + $0] }
        let cells: [NSView] = (0..<7).map { column in
            dayCell(rowDays[column], title: titles[row * 7 + column], column: column, showsSubtitle: showsSubtitle, config: config)
        }
        guard config.settings.showWeekNumbers, let first = rowDays.first else {
            return gridRow(leading: nil, cells: cells)
        }
        let week = calendarModel.weekNumber(for: first.date, weekRule: config.settings.weekRule)
        return gridRow(leading: weekColumn(String(week), showsSubtitle: showsSubtitle), cells: cells)
    }

    /// A row of 7 equal-width columns, with an optional narrow leading column
    /// (week number) — matching the design's `26px repeat(7,1fr)` grid.
    private func gridRow(leading: NSView?, cells: [NSView]) -> NSView {
        let columns = NSStackView(views: cells)
        columns.orientation = .horizontal
        columns.distribution = .fillEqually
        columns.spacing = Metrics.gridGap
        guard let leading else { return columns }
        let row = NSStackView(views: [leading, columns])
        row.orientation = .horizontal
        row.distribution = .fill
        row.spacing = Metrics.gridGap
        columns.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return row
    }

    private func dayCell(_ day: CalendarDay, title: CalendarDayTitle, column: Int, showsSubtitle: Bool, config: CalendarMonthViewConfig) -> CalendarDateCell {
        let state = CalendarDateCellState(
            title: title,
            isToday: day.isToday,
            isSelected: day.date == config.selectedDate,
            isOutsideMonth: day.isOutsideMonth,
            isWeekend: isWeekendColumn(index: column, rule: config.settings.weekRule),
            showsSubtitle: showsSubtitle,
            events: config.eventsByDay[day.date.key] ?? []
        )
        let item = CalendarDateCell(state: state, target: self, action: #selector(selectDate))
        item.localDate = day.date
        return item
    }

    private func isWeekendColumn(index: Int, rule: CalendarWeekRule) -> Bool {
        let weekday = rule.weekdayIndices[index]
        return weekday == 0 || weekday == 6
    }

    private func weekdayLabel(_ text: String, weekend: Bool) -> NSView {
        UI.label(text, font: Typography.mono(10, .medium), color: weekend ? Palette.ink4 : Palette.ink3, align: .center, tracking: 0.5)
    }

    private func weekHeaderColumn() -> NSView {
        let item = NSTextField(labelWithString: "#")
        item.alignment = .center
        item.font = Typography.mono(10)
        item.textColor = Palette.ink4
        item.widthAnchor.constraint(equalToConstant: Metrics.weekColumnWidth).isActive = true
        return item
    }

    // Intrinsic heights of the day cell's two label lines, measured once so the
    // week column can mirror the exact same line boxes.
    private static let dayNumberHeight = measuredHeight(font: Typography.mono(15, .medium))
    private static let daySubtitleHeight = measuredHeight(font: Typography.sans(10))

    private static func measuredHeight(font: NSFont) -> CGFloat {
        let label = NSTextField(labelWithString: "8")
        label.font = font
        return label.intrinsicContentSize.height
    }

    /// The week number, laid out to mirror the day cell's number: it sits in a
    /// box the height of the day number, above an equal-height subtitle spacer
    /// (only when the grid reserves a subtitle line), centered with the same
    /// offset. This keeps the week number aligned with the date number whether
    /// the grid is tall (lunar/holiday present) or compact.
    private func weekColumn(_ text: String, showsSubtitle: Bool) -> NSView {
        let label = NSTextField(labelWithString: text)
        label.alignment = .center
        label.font = Typography.mono(10)
        label.textColor = Palette.ink4
        label.translatesAutoresizingMaskIntoConstraints = false

        let numberBox = NSView()
        numberBox.translatesAutoresizingMaskIntoConstraints = false
        numberBox.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: numberBox.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: numberBox.centerYAnchor),
            numberBox.heightAnchor.constraint(equalToConstant: Self.dayNumberHeight)
        ])

        let stack = NSStackView(views: [numberBox])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 1
        stack.translatesAutoresizingMaskIntoConstraints = false
        if showsSubtitle {
            let spacer = NSView()
            spacer.translatesAutoresizingMaskIntoConstraints = false
            spacer.heightAnchor.constraint(equalToConstant: Self.daySubtitleHeight).isActive = true
            stack.addArrangedSubview(spacer)
        }

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: Metrics.weekColumnWidth),
            container.heightAnchor.constraint(equalToConstant: showsSubtitle ? Metrics.cellHeight : Metrics.compactCellHeight),
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            // Matches CalendarDateCell's label-stack offset (-1 tall, 0 compact).
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: showsSubtitle ? -1 : 0)
        ])
        return container
    }

    @objc private func selectDate(_ sender: CalendarDateCell) {
        guard let date = sender.localDate else { return }
        onSelectDate(date)
    }
}
