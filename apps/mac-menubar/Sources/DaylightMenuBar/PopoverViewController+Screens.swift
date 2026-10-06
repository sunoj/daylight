// Popover screen construction and shared container helpers.
// Exports: PopoverViewController screen builders
// Deps: AppKit, settings and feature panels

import AppKit

extension PopoverViewController {
    func settingsScreen() -> NSView {
        // Settings is taller than a small display's menu bar popover allows;
        // scroll it so the last row (Quit) is always reachable.
        scrollCapped(settingsPanel(), maxHeight: Metrics.settingsMaxHeight())
    }

    private func settingsPanel() -> NSView {
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
            onAllow: { [weak self] in self?.moonWantsLocation = true; self?.show(.moon) }
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

    /// Hugs its content up to `maxHeight`, then scrolls.
    func scrollCapped(_ content: NSView, maxHeight: CGFloat) -> NSScrollView {
        let document = FlippedView()
        content.translatesAutoresizingMaskIntoConstraints = false
        document.translatesAutoresizingMaskIntoConstraints = false
        document.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: document.topAnchor),
            content.leadingAnchor.constraint(equalTo: document.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: document.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: document.bottomAnchor)
        ])
        let scroll = NSScrollView()
        scroll.documentView = document
        document.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor).isActive = true
        scroll.drawsBackground = false
        scroll.hasHorizontalScroller = false
        scroll.hasVerticalScroller = true
        scroll.scrollerStyle = .overlay
        scroll.borderType = .noBorder
        scroll.translatesAutoresizingMaskIntoConstraints = false
        let hug = scroll.heightAnchor.constraint(equalTo: document.heightAnchor)
        hug.priority = .defaultHigh
        NSLayoutConstraint.activate([hug, scroll.heightAnchor.constraint(lessThanOrEqualToConstant: maxHeight)])
        return scroll
    }

    func flexSpacer() -> NSView {
        let view = NSView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return view
    }
}
