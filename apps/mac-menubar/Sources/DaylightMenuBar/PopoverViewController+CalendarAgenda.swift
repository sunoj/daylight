// Selected-day agenda for Sol's month screen.
// Exports: PopoverViewController Sol agenda composition
// Deps: AppKit, EventListSections, HolidayDetailEntry, SolCalendarEventRow

import AppKit

final class SolCalendarAgendaSection: NSStackView {
    private let holidays: [HolidayDetailEntry]
    private let events: [CalendarEvent]
    private let use24Hour: Bool
    private let onOpenEvent: (CalendarEvent) -> Void

    init(
        holidays: [HolidayDetailEntry],
        events: [CalendarEvent],
        use24Hour: Bool,
        onOpenEvent: @escaping (CalendarEvent) -> Void
    ) {
        self.holidays = holidays
        self.events = events
        self.use24Hour = use24Hour
        self.onOpenEvent = onOpenEvent
        super.init(frame: .zero)
        orientation = .vertical
        spacing = 8
        alignment = .leading
        render()
    }

    required init?(coder: NSCoder) { nil }

    private func render() {
        let sections = EventListSections.build(holidays: holidays, events: events, now: Date())
        let header = sectionHeader(count: holidays.count + events.count)
        let card = UI.card(eventScroll(sections: sections))
        addArrangedSubview(header)
        addArrangedSubview(card)
        header.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        card.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }

    private func sectionHeader(count: Int) -> NSView {
        let countLabel = UI.label(String(count), font: Typography.mono(11), color: Palette.ink4)
        let row = NSStackView(views: [UI.sectionHeader(L("日程")), agendaSpacer(), countLabel])
        row.orientation = .horizontal
        return row
    }

    private func eventScroll(sections: EventListSections) -> NSScrollView {
        let rows = NSStackView()
        rows.orientation = .vertical
        rows.spacing = 2
        rows.alignment = .leading
        sections.holidays.forEach { rows.addArrangedSubview(holidayRow($0)) }
        sections.allDay.forEach { rows.addArrangedSubview(eventRow($0)) }
        sections.past.forEach { rows.addArrangedSubview(eventRow($0)) }
        sections.upcoming.forEach { rows.addArrangedSubview(eventRow($0)) }
        rows.arrangedSubviews.forEach {
            $0.widthAnchor.constraint(equalTo: rows.widthAnchor).isActive = true
        }

        let document = NSView()
        document.translatesAutoresizingMaskIntoConstraints = false
        rows.translatesAutoresizingMaskIntoConstraints = false
        document.addSubview(rows)
        NSLayoutConstraint.activate([
            rows.topAnchor.constraint(equalTo: document.topAnchor),
            rows.leadingAnchor.constraint(equalTo: document.leadingAnchor),
            rows.trailingAnchor.constraint(equalTo: document.trailingAnchor),
            rows.bottomAnchor.constraint(equalTo: document.bottomAnchor),
            rows.widthAnchor.constraint(equalTo: document.widthAnchor)
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
        NSLayoutConstraint.activate([
            hug,
            scroll.heightAnchor.constraint(lessThanOrEqualToConstant: Metrics.solAgendaMaxHeight)
        ])
        return scroll
    }

    private func eventRow(_ event: CalendarEvent) -> NSView {
        SolCalendarEventRow(
            event: event,
            use24Hour: use24Hour,
            target: self,
            action: #selector(openEvent)
        )
    }

    private func holidayRow(_ entry: HolidayDetailEntry) -> NSView {
        let marker = UI.roundedBox(fill: entry.badgeColor, radius: 999)
        marker.widthAnchor.constraint(equalToConstant: 4).isActive = true
        marker.heightAnchor.constraint(equalToConstant: 26).isActive = true
        let title = UI.label(entry.displayTitle, font: Typography.sans(13), color: Palette.ink)
        let subtitle = UI.label(entry.displaySubtitle, font: Typography.sans(11), color: Palette.ink3)
        subtitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let text = NSStackView(views: [title, subtitle])
        text.orientation = .vertical
        text.spacing = 1
        text.alignment = .leading
        let row = NSStackView(views: [marker, text, agendaSpacer()])
        row.orientation = .horizontal
        row.spacing = 9
        row.alignment = .centerY
        row.edgeInsets = NSEdgeInsets(top: 7, left: 10, bottom: 7, right: 10)
        return row
    }

    private func agendaSpacer() -> NSView {
        let view = NSView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return view
    }

    @objc private func openEvent(_ sender: CalendarEventRowButton) {
        onOpenEvent(sender.event)
    }
}

extension PopoverViewController {
    func calendarAgendaSection(eventsByDay: [String: [CalendarEvent]]) -> NSView? {
        let events = eventsByDay[selectedDate.key] ?? []
        let holidays = HolidayDetailEntries.entries(for: selectedDate, store: store)
        guard !events.isEmpty || !holidays.isEmpty else { return nil }
        let settings = store.settings()
        let section = SolCalendarAgendaSection(
            holidays: holidays,
            events: events,
            use24Hour: settings.statusUse24HourTime,
            onOpenEvent: { SystemCalendarService.shared.openInCalendar($0) }
        )
        return pad(section, top: 0, left: 16, bottom: 12, right: 16)
    }
}
