// Luna screen composition and system-calendar actions.
// Exports: PopoverViewController Luna screen wiring
// Deps: AppKit, Luna views, SystemCalendarService, DaylightStore

import AppKit

extension PopoverViewController {
    func lunaScreen() -> NSView {
        guard viewMode == .month else { return lunaPeriodScreen() }
        let settings = store.settings()
        let days = calendarModel.monthGrid(
            year: visibleMonth.year,
            month: visibleMonth.month,
            today: calendarModel.today(),
            weekRule: settings.weekRule
        )
        let eventsByDay: [String: [CalendarEvent]]
        let service = SystemCalendarService.shared
        if settings.systemCalendarEnabled, let first = days.first, let last = days.last {
            eventsByDay = service.eventsByDay(
                from: first.date,
                to: last.date,
                hiddenCalendarIds: settings.hiddenCalendarIds
            )
        } else {
            eventsByDay = [:]
        }
        let selectedEvents = eventsByDay[selectedDate.key] ?? []
        let selectedHolidays = HolidayDetailEntries.entries(for: selectedDate, store: store)
        let selectedThoughts = store.thoughts(for: selectedDate)
        let allEvents = uniqueEvents(in: eventsByDay)
        let authorization = settings.systemCalendarEnabled ? service.authorization : .authorized

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 0
        stack.alignment = .leading
        add(LunaHeaderView(
            title: Loc.monthTitle(year: visibleMonth.year, month: visibleMonth.month, compact: true),
            lunarSubtitle: settings.lunaShowLunarDate ? lunaHeaderSubtitle() : nil,
            onPrevious: { [weak self] in self?.previousPeriod() },
            onNext: { [weak self] in self?.nextPeriod() },
            onJumpToday: { [weak self] in self?.jumpToday() },
            onZoomOut: { [weak self] in self?.zoomOut() }
        ), to: stack)
        add(LunaMonthGridView(
            store: store,
            calendarModel: calendarModel,
            lunarCalendar: lunarCalendar,
            year: visibleMonth.year,
            month: visibleMonth.month,
            selectedDate: selectedDate,
            settings: settings,
            eventsByDay: eventsByDay,
            onSelectDate: { [weak self] date in self?.selectDate(date) }
        ), to: stack)
        add(EventListPanel(
            selectedDate: selectedDate,
            holidays: selectedHolidays,
            events: selectedEvents,
            authorization: authorization,
            showLunarDate: settings.lunaShowLunarDate,
            thoughts: selectedThoughts,
            diaryComposerRow: lunaDiaryComposing ? quickDiaryInputRow(appearance: .lunaPanel) : nil,
            use24Hour: settings.statusUse24HourTime,
            onOpenEvent: { service.openInCalendar($0) },
            onOpenMoon: { [weak self] date in self?.showMoon(for: date) },
            onRequestAccess: { [weak self] in self?.requestLunaCalendarAccess() },
            onToggleThought: { [weak self] id in
                guard let self else { return }
                self.store.toggleThought(id: id)
                self.onDataChanged()
                self.render()
            },
            onDeleteThought: { [weak self] id in
                guard let self else { return }
                self.store.deleteThought(id: id)
                self.onDataChanged()
                self.showToast(L("已删除"))
                self.render()
            }
        ), to: stack)
        add(LunaFooterView(
            events: allEvents,
            onOpenSettings: { [weak self] in self?.openSettings() },
            onOpenEvent: { service.openInCalendar($0) },
            onNewThought: { [weak self] in
                guard let self else { return }
                self.lunaDiaryComposing.toggle()
                self.render()
            }
        ), to: stack)
        return stack
    }

    /// Luna's month/year/decade picker: the same grid Sol zooms out to, sized to
    /// Luna's narrower shell. The agenda drops away — there is no selected day to
    /// list — but the footer stays so settings remain one tap away, minus the
    /// new-entry button, which has nothing to write into here.
    private func lunaPeriodScreen() -> NSView {
        let settings = store.settings()
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 0
        stack.alignment = .leading
        add(LunaHeaderView(
            title: CalendarPeriod.period(for: visibleMonth, mode: viewMode).title,
            lunarSubtitle: settings.lunaShowLunarDate ? lunaPeriodSubtitle() : nil,
            onPrevious: { [weak self] in self?.previousPeriod() },
            onNext: { [weak self] in self?.nextPeriod() },
            onJumpToday: { [weak self] in self?.jumpToday() },
            onZoomOut: { [weak self] in self?.zoomOut() }
        ), to: stack)
        let grid = CalendarPeriodGridView(
            visibleDate: visibleMonth,
            selectedDate: selectedDate,
            mode: viewMode,
            lunarCalendar: settings.lunaShowLunarDate ? lunarCalendar : nil,
            contentWidth: Metrics.lunaPopoverWidth - Metrics.contentInset * 2,
            onSelect: { [weak self] date, mode in self?.selectPeriod(date, nextMode: mode) }
        )
        add(pad(grid, top: 0, left: 14, bottom: 14, right: 14), to: stack)
        add(LunaFooterView(
            events: [],
            onOpenSettings: { [weak self] in self?.openSettings() },
            onOpenEvent: { SystemCalendarService.shared.openInCalendar($0) },
            onNewThought: nil
        ), to: stack)
        return stack
    }

    private func lunaPeriodSubtitle() -> String? {
        guard viewMode == .year else { return nil }
        return LunarPeriodLabel.yearName(visibleMonth.year, lunarCalendar: lunarCalendar)
    }

    /// Lunar year and month for the visible month, as Sol shows under its title.
    private func lunaHeaderSubtitle() -> String? {
        guard let lunar = lunarCalendar.lunarDate(for: LocalDate(year: visibleMonth.year, month: visibleMonth.month, day: 1)) else {
            return nil
        }
        return "\(lunar.yearName)年 · \(lunar.monthName)月"
    }

    private func uniqueEvents(in eventsByDay: [String: [CalendarEvent]]) -> [CalendarEvent] {
        Array(Set(eventsByDay.values.flatMap { $0 })).sorted {
            if $0.start != $1.start { return $0.start < $1.start }
            return $0.id < $1.id
        }
    }

    private func requestLunaCalendarAccess() {
        let settings = store.settings()
        guard settings.systemCalendarEnabled else {
            var enabled = settings
            enabled.systemCalendarEnabled = true
            store.saveSettings(enabled)
            onDataChanged()
            render()
            return
        }

        let service = SystemCalendarService.shared
        switch service.authorization {
        case .notDetermined:
            service.requestAccess { [weak self] _ in self?.render() }
        case .denied, .restricted:
            openCalendarPreferences()
        case .authorized:
            render()
        }
    }

    func openCalendarPreferences() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") else { return }
        NSWorkspace.shared.open(url)
    }
}
