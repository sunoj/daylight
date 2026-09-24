// System calendar picker — master switch, authorization, per-calendar visibility.
// Exports: SystemCalendarPanel, CalendarToggleButton
// Deps: AppKit, DaylightStore, SystemCalendarService, DesignSystem, Components

import AppKit

final class CalendarToggleButton: RowButton {
    var calendarId: String = ""
}

final class SystemCalendarPanel: NSStackView {
    private let store: DaylightStore
    private let onDataChanged: () -> Void
    private let onNeedsRender: () -> Void
    private let onClose: () -> Void

    init(
        store: DaylightStore,
        onDataChanged: @escaping () -> Void,
        onNeedsRender: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.store = store
        self.onDataChanged = onDataChanged
        self.onNeedsRender = onNeedsRender
        self.onClose = onClose
        super.init(frame: .zero)
        orientation = .vertical
        spacing = 8
        alignment = .leading
        edgeInsets = NSEdgeInsets(top: 4, left: 4, bottom: 10, right: 4)
        render()
    }

    required init?(coder: NSCoder) { nil }

    private func render() {
        arrangedSubviews.forEach { $0.removeFromSuperview() }
        let settings = store.settings()
        let service = SystemCalendarService.shared
        full(header())
        full(group([
            toggleRow("calendar", L("显示系统日历"), settings.systemCalendarEnabled, #selector(toggleMaster))
        ]))
        guard settings.systemCalendarEnabled else { return }
        switch service.authorization {
        case .notDetermined:
            full(authorizationCard(canRequestAccess: true))
        case .denied, .restricted:
            full(authorizationCard(canRequestAccess: false))
        case .authorized:
            renderCalendars(settings: settings, calendars: service.calendars())
        }
    }

    private func renderCalendars(settings: UserSettings, calendars: [SystemCalendarInfo]) {
        section(L("选择要显示的日历"))
        let grouped = Dictionary(grouping: calendars, by: \.sourceTitle)
            .sorted { $0.key < $1.key }
        for (source, items) in grouped {
            section(source)
            full(group(items.map { calendarRow($0, hiddenIds: settings.hiddenCalendarIds) }))
        }
    }

    // MARK: Actions

    @objc func close() { onClose() }

    @objc func toggleMaster(_ sender: PillToggle) {
        update { $0.systemCalendarEnabled = sender.isOn }
    }

    @objc func requestAccess() {
        SystemCalendarService.shared.requestAccess { [weak self] _ in self?.onNeedsRender() }
    }

    @objc func ignoreToggleInteraction() {}

    @objc func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") else { return }
        NSWorkspace.shared.open(url)
    }

    @objc func toggleCalendar(_ sender: CalendarToggleButton) {
        let calendarId = sender.calendarId
        update { settings in
            settings.hiddenCalendarIds = SystemCalendarVisibility.toggleVisibility(
                calendarId: calendarId,
                hiddenIds: settings.hiddenCalendarIds
            )
        }
    }

    func update(_ change: (inout UserSettings) -> Void) {
        var settings = store.settings()
        change(&settings)
        store.saveSettings(settings)
        onDataChanged()
        onNeedsRender()
    }

    // MARK: Structure

    private func full(_ view: NSView) {
        addArrangedSubview(view)
        view.widthAnchor.constraint(equalTo: widthAnchor, constant: -8).isActive = true
    }

    private func section(_ title: String) {
        let header = UI.sectionHeader(title)
        addArrangedSubview(header)
        header.widthAnchor.constraint(equalTo: widthAnchor, constant: -8).isActive = true
    }
}
