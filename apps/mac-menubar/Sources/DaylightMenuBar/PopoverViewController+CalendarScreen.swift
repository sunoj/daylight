// Calendar screen composition for PopoverViewController (header, grid, diary).
// Exports: PopoverViewController calendar builders
// Deps: AppKit, Calendar views, SystemCalendarService, DesignSystem, Components

import AppKit

extension PopoverViewController {
    func calendarScreen() -> NSView {
        let eventsByDay = calendarEventsByDay(settings: store.settings())
        return calendarScreen(eventsByDay: eventsByDay)
    }

    func calendarScreen(eventsByDay: [String: [CalendarEvent]]) -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 0
        stack.alignment = .leading
        add(header(), to: stack)
        add(gridSection(eventsByDay: eventsByDay), to: stack)
        if viewMode == .month {
            if let agenda = calendarAgendaSection(eventsByDay: eventsByDay) {
                add(agenda, to: stack)
            }
            add(UI.hairline(), to: stack)
            let moonButton = RowButton(target: self, action: #selector(openMoon))
            moonButton.addContentView(MoonPhasePanel(displayDate: selectedDate, showLunarSuffix: store.settings().showLunarDate))
            let readouts = NSStackView(views: [moonButton])
            readouts.orientation = .horizontal
            readouts.alignment = .centerY
            readouts.spacing = 12
            if store.settings().showLunarDate, let term = lunarCalendar.solarTerm(for: selectedDate) {
                let icon = SolarTermIconView(term: term, variant: .small)
                NSLayoutConstraint.activate([
                    icon.widthAnchor.constraint(equalToConstant: 24),
                    icon.heightAnchor.constraint(equalToConstant: 24)
                ])
                readouts.addArrangedSubview(icon)
            }
            add(pad(readouts, top: 14, left: 16, bottom: 14, right: 16), to: stack)
            add(UI.hairline(), to: stack)
            add(quickDiarySection(), to: stack)
        }
        return stack
    }

    private func header() -> NSView {
        let title = UI.label(headerTitle(), font: Typography.sans(17, .semibold), color: Palette.ink, align: .center)
        let titleButton = RowButton(target: self, action: #selector(zoomOut))
        let titleWidth = (title.stringValue as NSString).size(withAttributes: [.font: title.font!]).width
        titleButton.widthAnchor.constraint(greaterThanOrEqualToConstant: ceil(titleWidth) + 4).isActive = true
        // The lunar subtitle only appears when 显示农历 is on: the lunar year and
        // month in month view, the 干支 year alone once zoomed out to the year.
        if store.settings().showLunarDate, let subtitle = headerSubtitle() {
            let sub = UI.label(subtitle, font: Typography.sans(11), color: Palette.ink3, align: .center)
            let column = NSStackView(views: [title, sub])
            column.orientation = .vertical
            column.spacing = 3
            titleButton.addContentView(column)
        } else {
            titleButton.addContentView(title)
        }
        let left = NSStackView(views: [tile("chevron.left", #selector(previousPeriod)), tile("calendar", #selector(jumpToday))])
        left.orientation = .horizontal
        left.spacing = 8
        let right = NSStackView(views: [tile("gearshape", #selector(openSettings)), tile("chevron.right", #selector(nextPeriod))])
        right.orientation = .horizontal
        right.spacing = 8
        // The design lays this row out as `justify-content: space-between` with equal
        // left/right tile groups, which centers the title. Two independent flex spacers
        // express that ambiguously — the engine may hand all the slack to either one, so
        // the title drifts left or right between renders. Pin them to equal widths.
        let leadingSpace = flexSpacer()
        let trailingSpace = flexSpacer()
        let row = NSStackView(views: [left, leadingSpace, titleButton, trailingSpace, right])
        row.orientation = .horizontal
        row.spacing = 8
        row.alignment = .centerY
        leadingSpace.widthAnchor.constraint(equalTo: trailingSpace.widthAnchor).isActive = true
        return pad(row, top: 15, left: 16, bottom: 11, right: 16)
    }

    private func gridSection(eventsByDay: [String: [CalendarEvent]]) -> NSView {
        if viewMode != .month {
            let grid = CalendarPeriodGridView(
                visibleDate: visibleMonth,
                selectedDate: selectedDate,
                mode: viewMode,
                lunarCalendar: store.settings().showLunarDate ? lunarCalendar : nil,
                onSelect: { [weak self] date, mode in self?.selectPeriod(date, nextMode: mode) }
            )
            return pad(grid, top: 0, left: 14, bottom: 14, right: 14)
        }
        let months = NSStackView()
        months.orientation = .vertical
        months.spacing = 12
        months.alignment = .leading
        add(calendarMonth(year: visibleMonth.year, month: visibleMonth.month, eventsByDay: eventsByDay), to: months)
        return pad(months, top: 0, left: 14, bottom: 14, right: 14)
    }

    private func calendarMonth(year: Int, month: Int, eventsByDay: [String: [CalendarEvent]] = [:]) -> NSView {
        CalendarMonthView(
            store: store,
            calendarModel: calendarModel,
            lunarCalendar: lunarCalendar,
            config: CalendarMonthViewConfig(
                year: year,
                month: month,
                selectedDate: selectedDate,
                settings: store.settings(),
                eventsByDay: eventsByDay
            ),
            onSelectDate: { [weak self] date in self?.selectDate(date) }
        )
    }

    private func calendarEventsByDay(settings: UserSettings) -> [String: [CalendarEvent]] {
        guard viewMode == .month, settings.systemCalendarEnabled else { return [:] }
        let grid = calendarModel.monthGrid(
            year: visibleMonth.year,
            month: visibleMonth.month,
            today: calendarModel.today(),
            weekRule: settings.weekRule
        )
        guard let first = grid.first, let last = grid.last else { return [:] }
        return SystemCalendarService.shared.eventsByDay(
            from: first.date,
            to: last.date,
            hiddenCalendarIds: settings.hiddenCalendarIds
        )
    }

    private func headerTitle() -> String {
        if viewMode == .month {
            return String(format: "%04d.%02d", Loc.displayYear(visibleMonth.year), visibleMonth.month)
        }
        return CalendarPeriod.period(for: visibleMonth, mode: viewMode).title
    }

    private func headerSubtitle() -> String? {
        switch viewMode {
        case .month:
            guard let lunar = lunarCalendar.lunarDate(for: LocalDate(year: visibleMonth.year, month: visibleMonth.month, day: 1)) else {
                return nil
            }
            return "\(lunar.yearName)年 · \(lunar.monthName)月"
        case .year:
            return LunarPeriodLabel.yearName(visibleMonth.year, lunarCalendar: lunarCalendar)
        // A decade or century spans ten or a hundred 干支 years; naming one would
        // be arbitrary, so those titles stay bare.
        case .decade, .century:
            return nil
        }
    }

    private func tile(_ symbol: String, _ action: Selector) -> NSView {
        let button = RowButton(target: self, action: action)
        let box = UI.roundedBox(fill: Palette.surface2, radius: Metrics.tileRadius)
        box.widthAnchor.constraint(equalToConstant: 30).isActive = true
        box.heightAnchor.constraint(equalToConstant: 30).isActive = true
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: symbol)?
            .withSymbolConfiguration(.init(pointSize: 14, weight: .medium))
        let glyph = NSImageView(image: image ?? NSImage())
        glyph.contentTintColor = Palette.ink2
        glyph.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(glyph)
        NSLayoutConstraint.activate([
            glyph.centerXAnchor.constraint(equalTo: box.centerXAnchor),
            glyph.centerYAnchor.constraint(equalTo: box.centerYAnchor)
        ])
        button.addContentView(box)
        return button
    }
}
