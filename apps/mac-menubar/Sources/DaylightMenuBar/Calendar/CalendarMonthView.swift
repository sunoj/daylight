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

/// Laid out by frame: the weekday row and six rows of stack views (plus a
/// week-number column) were re-solved by Auto Layout on every render.
final class CalendarMonthView: NSView {
    private let calendarModel: CalendarModel
    private let titleFormatter: CalendarDayTitleFormatter
    private let onSelectDate: (LocalDate) -> Void
    private var weekdayLabels: [NSView] = []
    private var weekHeader: NSView?
    private var cells: [CalendarDateCell] = []
    private var weekLabels: [NSTextField] = []
    private var showsSubtitle = true

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
        render(config)
    }

    required init?(coder: NSCoder) { nil }

    override var isFlipped: Bool { true }

    private func render(_ config: CalendarMonthViewConfig) {
        let rule = config.settings.weekRule
        weekdayLabels = rule.weekdayLabels.enumerated().map { index, label in
            weekdayLabel(label.uppercased(), weekend: isWeekendColumn(index: index, rule: rule))
        }
        let days = calendarModel.monthGrid(year: config.year, month: config.month, today: calendarModel.today(), weekRule: rule)
        let titles = days.map { titleFormatter.titleParts(for: $0, settings: config.settings) }
        // One height for the whole grid: reserve the subtitle line only if any
        // day actually has one (lunar/solar term, or a holiday name even with
        // 农历 off). Otherwise the grid collapses to the compact height.
        showsSubtitle = titles.contains { $0.secondary != nil }
        cells = days.enumerated().map { index, day in
            dayCell(day, title: titles[index], column: index % 7, config: config)
        }
        if config.settings.showWeekNumbers {
            weekHeader = weekHeaderColumn()
            weekLabels = stride(from: 0, to: days.count, by: 7).map { index in
                weekLabel(String(calendarModel.weekNumber(for: days[index].date, weekRule: rule)))
            }
        }
        for view in weekdayLabels + [weekHeader].compactMap({ $0 }) + cells + weekLabels {
            view.translatesAutoresizingMaskIntoConstraints = true
            addSubview(view)
        }
    }

    private var weekdayHeight: CGFloat {
        (weekdayLabels + [weekHeader].compactMap { $0 }).map(\.intrinsicContentSize.height).max() ?? 0
    }

    private var cellHeight: CGFloat {
        showsSubtitle ? Metrics.cellHeight : Metrics.compactCellHeight
    }

    override var intrinsicContentSize: NSSize {
        let rows = CGFloat(cells.count / 7)
        return NSSize(width: NSView.noIntrinsicMetric,
                      height: weekdayHeight + Metrics.gridGap + rows * cellHeight + max(rows - 1, 0) * Metrics.gridGap)
    }

    /// Seven equal columns, with an optional narrow leading column (week
    /// number) — matching the design's `26px repeat(7,1fr)` grid.
    override func layout() {
        super.layout()
        let gap = Metrics.gridGap
        let leading = weekHeader == nil ? 0 : Metrics.weekColumnWidth + gap
        let columnWidth = (bounds.width - leading - 6 * gap) / 7
        let x = { (column: Int) in leading + CGFloat(column) * (columnWidth + gap) }

        let headerHeight = weekdayHeight
        for (column, label) in weekdayLabels.enumerated() {
            label.frame = aligned(NSRect(x: x(column), y: 0, width: columnWidth, height: headerHeight))
        }
        weekHeader?.frame = aligned(NSRect(x: 0, y: 0, width: Metrics.weekColumnWidth, height: headerHeight))

        var y = headerHeight + gap
        for row in 0..<(cells.count / 7) {
            for column in 0..<7 {
                cells[row * 7 + column].frame = aligned(NSRect(x: x(column), y: y, width: columnWidth, height: cellHeight))
            }
            if row < weekLabels.count { layoutWeekLabel(weekLabels[row], rowTop: y) }
            y += cellHeight + gap
        }
    }

    /// The week number sits where the day cell's number sits: in a box the
    /// height of the day number, above an equal-height subtitle spacer when the
    /// grid reserves a subtitle line, centred 1pt above the row's centre in a
    /// tall grid. This keeps it aligned with the date number either way.
    private func layoutWeekLabel(_ label: NSTextField, rowTop: CGFloat) {
        let stackHeight = Self.dayNumberHeight + (showsSubtitle ? 1 + Self.daySubtitleHeight : 0)
        let stackTop = rowTop + cellHeight / 2 - (showsSubtitle ? 1 : 0) - stackHeight / 2
        let size = label.intrinsicContentSize
        label.frame = aligned(NSRect(x: (Metrics.weekColumnWidth - size.width) / 2,
                                     y: stackTop + (Self.dayNumberHeight - size.height) / 2,
                                     width: size.width, height: size.height))
    }

    private func aligned(_ rect: NSRect) -> NSRect {
        backingAlignedRect(rect, options: .alignAllEdgesNearest)
    }

    private func dayCell(_ day: CalendarDay, title: CalendarDayTitle, column: Int, config: CalendarMonthViewConfig) -> CalendarDateCell {
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
        return item
    }

    private func weekLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.alignment = .center
        label.font = Typography.mono(10)
        label.textColor = Palette.ink4
        return label
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

    @objc private func selectDate(_ sender: CalendarDateCell) {
        guard let date = sender.localDate else { return }
        onSelectDate(date)
    }
}
