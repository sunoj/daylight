// Popover screen construction and shared container helpers.
// Exports: PopoverViewController screen builders
// Deps: AppKit, settings and feature panels

import AppKit

extension PopoverViewController {
    func settingsScreen() -> NSView {
        pad(CalendarSettingsPanel(
            store: store,
            onDataChanged: onDataChanged,
            onNeedsRender: { [weak self] in self?.render() },
            onClose: { [weak self] in
                guard let self else { return }
                self.show(self.homeScreen)
            },
            onOpenStatusEditor: { [weak self] in self?.show(.statusEditor) },
            onOpenHolidays: { [weak self] in self?.show(.holidays) },
            onOpenSystemCalendar: { [weak self] in self?.show(.systemCalendar) },
            onToast: { [weak self] in self?.showToast($0) }
        ), top: 12, left: 14, bottom: 8, right: 14)
    }

    func locationPromptScreen() -> NSView {
        pad(LocationPromptPanel(
            onAllow: { [weak self] in self?.moonWantsLocation = true; self?.show(.moon) },
            onSkip: { [weak self] in self?.moonWantsLocation = false; self?.show(.moon) }
        ), top: 6, left: 14, bottom: 8, right: 14)
    }

    func moonScreen() -> NSView {
        pad(Moon3DPanel(displayDate: moonDisplayDate, requestLocation: moonWantsLocation, store: store, onClose: { [weak self] in
            guard let self else { return }
            self.show(self.homeScreen)
        }),
            top: 12, left: 14, bottom: 8, right: 14)
    }

    func holidaysScreen() -> NSView {
        pad(HolidaySubscriptionPanel(
            store: store,
            onDataChanged: onDataChanged,
            onNeedsRender: { [weak self] in self?.render() },
            onClose: { [weak self] in self?.show(.settings) },
            onToast: { [weak self] in self?.showToast($0) }
        ), top: 12, left: 14, bottom: 8, right: 14)
    }

    func systemCalendarScreen() -> NSView {
        pad(SystemCalendarPanel(
            store: store,
            onDataChanged: onDataChanged,
            onNeedsRender: { [weak self] in self?.render() },
            onClose: { [weak self] in self?.show(.settings) }
        ), top: 12, left: 14, bottom: 8, right: 14)
    }

    func statusEditorScreen() -> NSView {
        pad(StatusBarEditorPanel(
            store: store,
            calendarModel: calendarModel,
            onDataChanged: onDataChanged,
            onNeedsRender: { [weak self] in self?.render() },
            onClose: { [weak self] in self?.show(.settings) }
        ), top: 12, left: 14, bottom: 8, right: 14)
    }

    func pad(_ view: NSView, top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) -> NSView {
        let container = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: container.topAnchor, constant: top),
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: left),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -right),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -bottom)
        ])
        return container
    }

    func flexSpacer() -> NSView {
        let view = NSView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return view
    }
}
