// Higher-level year, decade, and century picker grids.
// Exports: CalendarPeriodGridView, LunarPeriodLabel
// Deps: AppKit, CalendarModel, CalendarViewMode, LunarCalendar

import AppKit
import Foundation

/// Lunar labels for the periods the higher-level grids list.
enum LunarPeriodLabel {
    /// The 干支 year a Gregorian year is known by — 2029 is 己酉年. A Gregorian
    /// year technically holds the tail of one and most of the next, so this
    /// reads the year at midsummer: always after that year's lunar new year and
    /// before the following one, which is the one people name the year after.
    static func yearName(_ year: Int, lunarCalendar: LunarCalendar) -> String? {
        guard let lunar = lunarCalendar.lunarDate(for: LocalDate(year: year, month: 7, day: 1)) else { return nil }
        return L("\(lunar.yearName)年")
    }

    /// The lunar month(s) a Gregorian month covers, the way printed Chinese
    /// calendars label a month page. A Gregorian month almost always straddles
    /// two lunar months, so the year grid shows the span rather than day one's
    /// month, which would read as though the whole of 7月 were 五月.
    static func monthSpan(year: Int, month: Int, lunarCalendar: LunarCalendar) -> String? {
        let first = LocalDate(year: year, month: month, day: 1)
        guard let start = lunarCalendar.lunarDate(for: first) else { return nil }
        guard let lastDay = lastDay(year: year, month: month),
              let end = lunarCalendar.lunarDate(for: LocalDate(year: year, month: month, day: lastDay)),
              end.monthName != start.monthName else {
            return L("\(start.monthName)月")
        }
        return L("\(start.monthName)月–\(end.monthName)月")
    }

    private static func lastDay(year: Int, month: Int) -> Int? {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date) else { return nil }
        return range.count
    }
}

final class CalendarPeriodButton: NSControl {
    var targetDate: LocalDate?
    var nextMode: CalendarViewMode?

    private let label = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(labelWithString: "")
    private var state: CalendarPeriodButtonState?

    fileprivate init(state: CalendarPeriodButtonState, target: AnyObject?, action: Selector) {
        super.init(frame: .zero)
        self.target = target
        self.action = action
        self.state = state
        configure(state)
    }

    required init?(coder: NSCoder) { nil }

    override func mouseDown(with event: NSEvent) {
        sendAction(action, to: target)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        if let state { applyColors(state) }
    }

    private func configure(_ state: CalendarPeriodButtonState) {
        wantsLayer = true
        alphaValue = state.isOutsidePeriod ? 0.3 : 1
        layer?.cornerRadius = Metrics.cellRadius
        applyColors(state)

        label.stringValue = state.title
        label.font = state.font
        label.alignment = .center
        label.lineBreakMode = .byClipping
        label.setContentCompressionResistancePriority(.required, for: .horizontal)

        let content = NSStackView(views: [label])
        content.orientation = .vertical
        content.alignment = .centerX
        content.spacing = 1
        content.translatesAutoresizingMaskIntoConstraints = false
        if let subtitle = state.subtitle {
            subtitleLabel.stringValue = subtitle
            subtitleLabel.font = Typography.sans(10)
            subtitleLabel.alignment = .center
            subtitleLabel.usesSingleLineMode = true
            subtitleLabel.maximumNumberOfLines = 1
            subtitleLabel.lineBreakMode = .byTruncatingTail
            subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            content.addArrangedSubview(subtitleLabel)
        }
        addSubview(content)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Metrics.cellHeight),
            content.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 4),
            content.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),
            content.centerXAnchor.constraint(equalTo: centerXAnchor),
            content.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private func applyColors(_ state: CalendarPeriodButtonState) {
        label.textColor = state.isSelected ? Palette.accentInk : Palette.ink
        subtitleLabel.textColor = state.isSelected ? Palette.accentInk : Palette.ink3
        layer?.backgroundColor = cg(state.isSelected ? Palette.accent : .clear)
        layer?.borderWidth = state.isSelected ? 0 : 1
        layer?.borderColor = cg(Palette.line)
    }
}

final class CalendarPeriodGridView: NSGridView {
    private let visibleDate: LocalDate
    private let selectedDate: LocalDate
    private let mode: CalendarViewMode
    /// Non-nil only while 显示农历 is on; the year grid then labels each month
    /// with the lunar months it spans.
    private let lunarCalendar: LunarCalendar?
    /// Content width the four columns divide up — Sol's popover by default,
    /// Luna's narrower shell when it hosts the same picker.
    private let contentWidth: CGFloat
    private let onSelect: (LocalDate, CalendarViewMode) -> Void

    init(
        visibleDate: LocalDate,
        selectedDate: LocalDate,
        mode: CalendarViewMode,
        lunarCalendar: LunarCalendar? = nil,
        contentWidth: CGFloat = Metrics.popoverWidth - Metrics.contentInset * 2,
        onSelect: @escaping (LocalDate, CalendarViewMode) -> Void
    ) {
        self.visibleDate = visibleDate
        self.selectedDate = selectedDate
        self.mode = mode
        self.lunarCalendar = lunarCalendar
        self.contentWidth = contentWidth
        self.onSelect = onSelect
        super.init(frame: .zero)
        rowSpacing = Metrics.gridGap
        columnSpacing = Metrics.gridGap
        xPlacement = .fill
        yPlacement = .fill
        widthAnchor.constraint(equalToConstant: contentWidth).isActive = true
        render()
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func render() {
        let items = gridItems()
        for row in 0..<3 {
            let gridRow = addRow(with: (0..<4).map { itemButton(items[row * 4 + $0]) })
            gridRow.height = Metrics.cellHeight
            gridRow.yPlacement = .fill
        }
        let columnWidth = (contentWidth - Metrics.gridGap * 3) / 4
        for index in 0..<4 {
            let gridColumn = column(at: index)
            gridColumn.width = columnWidth
            gridColumn.xPlacement = .fill
        }
    }

    private func gridItems() -> [PeriodGridItem] {
        switch mode {
        case .year:
            return (1...12).map { month in
                PeriodGridItem(
                    title: monthTitle(month),
                    subtitle: lunarCalendar.flatMap { LunarPeriodLabel.monthSpan(year: visibleDate.year, month: month, lunarCalendar: $0) },
                    date: LocalDate(year: visibleDate.year, month: month, day: 1),
                    nextMode: .month,
                    isOutsidePeriod: false
                )
            }
        case .decade:
            let start = (visibleDate.year / 10) * 10 - 1
            let periodStart = start + 1
            return (0..<12).map { itemForYear(start + $0, periodStart: periodStart) }
        case .century:
            let start = (visibleDate.year / 100) * 100 - 10
            let periodStart = start + 10
            return (0..<12).map { itemForDecade(start + $0 * 10, periodStart: periodStart) }
        case .month:
            return []
        }
    }

    private func itemForYear(_ year: Int, periodStart: Int) -> PeriodGridItem {
        PeriodGridItem(
            title: String(Loc.displayYear(year)),
            subtitle: lunarCalendar.flatMap { LunarPeriodLabel.yearName(year, lunarCalendar: $0) },
            date: LocalDate(year: year, month: 1, day: 1),
            nextMode: .year,
            isOutsidePeriod: year < periodStart || year > periodStart + 9
        )
    }

    private func itemForDecade(_ start: Int, periodStart: Int) -> PeriodGridItem {
        PeriodGridItem(
            title: "\(Loc.displayYear(start))–\(Loc.displayYear(start + 9))",
            subtitle: nil,
            date: LocalDate(year: start, month: 1, day: 1),
            nextMode: .decade,
            isOutsidePeriod: start < periodStart || start > periodStart + 90
        )
    }

    private func itemButton(_ item: PeriodGridItem) -> CalendarPeriodButton {
        let state = CalendarPeriodButtonState(
            title: item.title,
            subtitle: item.subtitle,
            isSelected: isSelected(item.date),
            isOutsidePeriod: item.isOutsidePeriod,
            font: item.nextMode == .month ? Typography.sans(13, .medium) : item.font
        )
        let button = CalendarPeriodButton(state: state, target: self, action: #selector(selectPeriod))
        button.targetDate = item.date
        button.nextMode = item.nextMode
        return button
    }

    private func isSelected(_ date: LocalDate) -> Bool {
        switch mode {
        case .year:
            return date.year == selectedDate.year && date.month == selectedDate.month
        case .decade:
            return date.year == selectedDate.year
        case .century:
            return date.year <= selectedDate.year && selectedDate.year <= date.year + 9
        case .month:
            return false
        }
    }

    private func monthTitle(_ month: Int) -> String {
        Loc.monthShort(month)
    }

    @objc private func selectPeriod(_ sender: CalendarPeriodButton) {
        guard let date = sender.targetDate, let mode = sender.nextMode else {
            return
        }
        onSelect(date, mode)
    }
}

private struct PeriodGridItem {
    let title: String
    let subtitle: String?
    let date: LocalDate
    let nextMode: CalendarViewMode
    let isOutsidePeriod: Bool

    var font: NSFont {
        nextMode == .decade ? Typography.mono(12.5, .medium) : Typography.mono(14, .medium)
    }
}

private struct CalendarPeriodButtonState {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let isOutsidePeriod: Bool
    let font: NSFont
}
