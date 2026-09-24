// Navigation, selection, and keyboard handling for PopoverViewController.
// Exports: PopoverViewController navigation
// Deps: AppKit, CalendarModel, LocationService, DaylightStore

import AppKit

extension PopoverViewController: NSTextFieldDelegate {
    // Keep the quick-diary save button disabled without a usable note or todo.
    func controlTextDidChange(_ obj: Notification) {
        guard (obj.object as? NSTextField) === quickDiaryField else { return }
        quickDiarySaveButton?.isEnabled = DiaryThoughtCodec.parseInput(quickDiaryField.stringValue) != nil
    }
}

extension PopoverViewController {
    func show(_ screen: PopoverScreen) {
        if self.screen == .luna && screen != .luna {
            lunaDiaryComposing = false
        }
        self.screen = screen
        render()
    }

    func selectDate(_ date: LocalDate) {
        selectedDate = date
        visibleMonth = LocalDate(year: date.year, month: date.month, day: 1)
        viewMode = .month
        render()
    }

    func selectPeriod(_ date: LocalDate, nextMode: CalendarViewMode) {
        selectedDate = date
        visibleMonth = LocalDate(year: date.year, month: date.month, day: 1)
        viewMode = nextMode
        render()
    }

    @objc func zoomOut() {
        let order: [CalendarViewMode] = [.month, .year, .decade, .century]
        guard let index = order.firstIndex(of: viewMode), index + 1 < order.count else { return }
        setViewMode(order[index + 1])
        render()
    }

    @objc func previousPeriod() {
        let step = CalendarPeriod.period(for: visibleMonth, mode: viewMode).previousStepMonths
        visibleMonth = calendarModel.addingMonths(to: visibleMonth, value: step)
        render()
    }

    @objc func nextPeriod() {
        let step = CalendarPeriod.period(for: visibleMonth, mode: viewMode).nextStepMonths
        visibleMonth = calendarModel.addingMonths(to: visibleMonth, value: step)
        render()
    }

    @objc func jumpToday() {
        selectedDate = calendarModel.today()
        visibleMonth = LocalDate(year: selectedDate.year, month: selectedDate.month, day: 1)
        viewMode = .month
        show(homeScreen)
    }

    @objc func openSettings() { show(.settings) }

    @objc func openMoon() {
        showMoon(for: selectedDate)
    }

    func showMoon(for date: LocalDate) {
        moonDisplayDate = date
        if LocationService.needsPermissionPrompt(store: store) {
            show(.locationPrompt)
        } else {
            moonWantsLocation = true
            show(.moon)
        }
    }

    @objc func saveQuickDiary() {
        guard let draft = DiaryThoughtCodec.parseInput(quickDiaryField.stringValue) else { return }
        store.addThought(for: selectedDate, content: draft.content, done: draft.done)
        onDataChanged()
        showToast(L("已保存"))
        render()
    }

    func handleKeyDown(_ event: NSEvent) -> Bool {
        switch event.keyCode {
        case 123: moveSelection(days: -1)
        case 124: moveSelection(days: 1)
        case 125: moveSelection(days: 7)
        case 126: moveSelection(days: -7)
        case 53:
            if screen == .luna && lunaDiaryComposing {
                lunaDiaryComposing = false
                render()
                return true
            }
            // Luna's picker is a state of the home screen, not a screen of its
            // own, so escape steps back into the month rather than closing.
            if screen == .luna && viewMode != .month {
                viewMode = .month
                render()
                return true
            }
            if screen != .calendar && screen != .luna {
                show(homeScreen)
            } else { return false }
        default: return handleCharacter(event.charactersIgnoringModifiers)
        }
        return true
    }

    private func handleCharacter(_ value: String?) -> Bool {
        let mode: CalendarViewMode
        switch value?.lowercased() {
        case "t": jumpToday(); return true
        case "m": mode = .month
        case "y": mode = .year
        case "d": mode = .decade
        case "c": mode = .century
        default: return false
        }
        setViewMode(mode)
        // Luna hosts the pickers in its own shell now, so these keys stay put
        // instead of dropping the reader into Sol.
        show(screen == .luna ? .luna : .calendar)
        return true
    }

    /// Leaving the month grid takes the Luna diary composer with it — the
    /// picker has no day to write an entry against.
    private func setViewMode(_ mode: CalendarViewMode) {
        viewMode = mode
        if mode != .month { lunaDiaryComposing = false }
    }

    private func moveSelection(days: Int) {
        selectedDate = calendarModel.addingDays(to: selectedDate, value: days)
        visibleMonth = LocalDate(year: selectedDate.year, month: selectedDate.month, day: 1)
        viewMode = .month
        render()
    }
}
