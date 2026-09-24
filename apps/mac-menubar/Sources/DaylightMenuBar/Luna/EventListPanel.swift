// Dark selected-day agenda with collapsed past events and authorization state.
// Exports: EventListPanel
// Deps: AppKit, CalendarEvent, EventListSections, SystemCalendarAuthorization, Components, DiaryThoughtTimelineView

import AppKit
import Foundation

final class EventListPanel: NSView {
    private let selectedDate: LocalDate
    private let holidays: [HolidayDetailEntry]
    private let events: [CalendarEvent]
    private let authorization: SystemCalendarAuthorization
    private let showLunarDate: Bool
    private let thoughts: [DiaryThought]
    private let diaryComposerRow: NSView?
    private let now: Date
    private let use24Hour: Bool
    private let onOpenEvent: (CalendarEvent) -> Void
    private let onOpenMoon: (LocalDate) -> Void
    private let onRequestAccess: () -> Void
    private let onToggleThought: (String) -> Void
    private let onDeleteThought: (String) -> Void
    private var pastExpanded = false
    private var eventByButton: [ObjectIdentifier: CalendarEvent] = [:]
    private var scrollHeight: NSLayoutConstraint?
    private weak var scrollView: NSScrollView?
    private weak var pastEventsView: NSView?

    init(
        selectedDate: LocalDate,
        holidays: [HolidayDetailEntry],
        events: [CalendarEvent],
        authorization: SystemCalendarAuthorization,
        showLunarDate: Bool,
        thoughts: [DiaryThought] = [],
        diaryComposerRow: NSView? = nil,
        now: Date = Date(),
        use24Hour: Bool = true,
        onOpenEvent: @escaping (CalendarEvent) -> Void,
        onOpenMoon: @escaping (LocalDate) -> Void,
        onRequestAccess: @escaping () -> Void,
        onToggleThought: @escaping (String) -> Void = { _ in },
        onDeleteThought: @escaping (String) -> Void = { _ in }
    ) {
        self.selectedDate = selectedDate
        self.holidays = holidays
        self.events = events
        self.authorization = authorization
        self.showLunarDate = showLunarDate
        self.thoughts = thoughts
        self.diaryComposerRow = diaryComposerRow
        self.now = now
        self.use24Hour = use24Hour
        self.onOpenEvent = onOpenEvent
        self.onOpenMoon = onOpenMoon
        self.onRequestAccess = onRequestAccess
        self.onToggleThought = onToggleThought
        self.onDeleteThought = onDeleteThought
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        render()
    }

    required init?(coder: NSCoder) { nil }

    private func render() {
        let background = UI.roundedBox(fill: Palette.popoverEventPanel, radius: 0)
        addSubview(background)
        NSLayoutConstraint.activate([
            background.topAnchor.constraint(equalTo: topAnchor),
            background.leadingAnchor.constraint(equalTo: leadingAnchor),
            background.trailingAnchor.constraint(equalTo: trailingAnchor),
            background.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        let content = NSStackView()
        content.orientation = .vertical
        content.spacing = 8
        content.alignment = .leading
        content.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(content)
        // Padding lives on these constraints, not on `edgeInsets`: every row
        // below pins its width to the stack's, which spans the insets and would
        // leave the title flush against the popover edge.
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: background.topAnchor, constant: 14),
            content.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 18),
            content.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -12)
        ])

        let heading = titleRow()
        content.addArrangedSubview(heading)
        heading.widthAnchor.constraint(equalTo: content.widthAnchor).isActive = true
        guard authorization == .authorized else {
            let authorization = authorizationView()
            content.addArrangedSubview(authorization)
            authorization.widthAnchor.constraint(equalTo: content.widthAnchor).isActive = true
            appendDiarySection(to: content)
            return
        }

        let sections = EventListSections.build(holidays: holidays, events: events, now: now)
        let scroll = eventScroll(sections: sections)
        content.addArrangedSubview(scroll)
        scroll.widthAnchor.constraint(equalTo: content.widthAnchor).isActive = true
        appendDiarySection(to: content)
    }

    private func appendDiarySection(to content: NSStackView) {
        guard let section = diarySection() else { return }
        content.addArrangedSubview(section)
        section.widthAnchor.constraint(equalTo: content.widthAnchor).isActive = true
    }

    private func diarySection() -> NSView? {
        guard !thoughts.isEmpty || diaryComposerRow != nil else { return nil }
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 8
        stack.alignment = .leading
        let hairline = UI.roundedBox(fill: Palette.eventLine, radius: 0)
        hairline.heightAnchor.constraint(equalToConstant: 1).isActive = true
        stack.addArrangedSubview(hairline)
        hairline.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        let title = UI.sectionHeader(L("日记"), color: Palette.eventInk3)
        let count = UI.label(String(thoughts.count), font: Typography.mono(11), color: Palette.eventInk3)
        let header = NSStackView(views: [title, spacer(), count])
        header.orientation = .horizontal
        header.alignment = .centerY
        stack.addArrangedSubview(header)
        header.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        if !thoughts.isEmpty {
            let timeline = DiaryThoughtTimelineView(style: .dark)
            timeline.translatesAutoresizingMaskIntoConstraints = false
            timeline.onToggle = onToggleThought
            timeline.onDelete = onDeleteThought
            timeline.render(thoughts: thoughts)
            stack.addArrangedSubview(timeline)
            timeline.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }
        if let diaryComposerRow {
            stack.addArrangedSubview(diaryComposerRow)
            diaryComposerRow.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }
        return stack
    }

    private func titleRow() -> NSView {
        let title = UI.label(isToday ? L("今天") : Loc.weekday(weekdayIndex), font: Typography.sans(13, .semibold), color: Palette.eventInk)
        let date = UI.label(longDate(), font: Typography.sans(13), color: Palette.eventInk2)
        date.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let moon = CompactMoonReadout(date: selectedDate, target: self, action: #selector(openMoon))
        // The date reads as a continuation of "今天", so it follows the label
        // rather than being pushed to the opposite edge.
        var views: [NSView] = [title, date, spacer()]
        if showLunarDate, let term = LunarCalendar().solarTerm(for: selectedDate) {
            let icon = SolarTermIconView(term: term, variant: .small)
            icon.tintColor = Palette.eventInk2
            NSLayoutConstraint.activate([
                icon.widthAnchor.constraint(equalToConstant: 20),
                icon.heightAnchor.constraint(equalToConstant: 20)
            ])
            views.append(icon)
        }
        views.append(moon)
        let row = NSStackView(views: views)
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8
        return row
    }

    private func authorizationView() -> NSView {
        let copy = UI.label(L("允许访问系统日历"), font: Typography.sans(12.5), color: Palette.eventInk3, align: .center)
        let button = UI.filledButton(
            L("授权访问日历"), target: self, action: #selector(requestAccess), height: 30,
            fill: Palette.eventInk, titleColor: Palette.eventPanel
        )
        let column = NSStackView(views: [copy, button])
        column.orientation = .vertical
        column.alignment = .centerX
        column.spacing = 10
        column.edgeInsets = NSEdgeInsets(top: 8, left: 0, bottom: 4, right: 0)
        return column
    }

    private func eventScroll(sections: EventListSections) -> NSView {
        let rows = NSStackView()
        rows.orientation = .vertical
        rows.alignment = .leading
        rows.spacing = 2
        rows.translatesAutoresizingMaskIntoConstraints = false

        if !sections.past.isEmpty {
            rows.addArrangedSubview(pastToggle())
            let past = NSStackView(views: sections.past.map(eventRow))
            past.orientation = .vertical
            past.alignment = .leading
            past.spacing = 2
            past.isHidden = !pastExpanded
            past.translatesAutoresizingMaskIntoConstraints = false
            rows.addArrangedSubview(past)
            for row in past.arrangedSubviews {
                row.widthAnchor.constraint(equalTo: past.widthAnchor).isActive = true
            }
            pastEventsView = past
        }

        sections.holidays.forEach { rows.addArrangedSubview(holidayRow($0)) }
        sections.allDay.forEach { rows.addArrangedSubview(eventRow($0)) }
        sections.upcoming.forEach { rows.addArrangedSubview(eventRow($0)) }
        if sections.isEmpty {
            let empty = UI.label(isToday ? L("今天没有日程") : L("没有日程"), font: Typography.sans(12.5), color: Palette.eventInk3, align: .center)
            rows.addArrangedSubview(empty)
        }
        for row in rows.arrangedSubviews {
            row.widthAnchor.constraint(equalTo: rows.widthAnchor).isActive = true
        }

        let document = NSView()
        document.translatesAutoresizingMaskIntoConstraints = false
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
        scroll.drawsBackground = false
        scroll.hasHorizontalScroller = false
        scroll.hasVerticalScroller = true
        scroll.scrollerStyle = .overlay
        scroll.borderType = .noBorder
        scroll.translatesAutoresizingMaskIntoConstraints = false
        // Hug the document, capped at 240. Pinning the height to
        // rows.fittingSize here measured a stack that was not yet in the
        // hierarchy and had no width, so the estimate came out too tall and
        // left dead space under the last event.
        let hug = scroll.heightAnchor.constraint(equalTo: document.heightAnchor)
        hug.priority = .defaultHigh
        scrollHeight = hug
        NSLayoutConstraint.activate([
            hug,
            scroll.heightAnchor.constraint(lessThanOrEqualToConstant: 240)
        ])
        scrollView = scroll
        return scroll
    }

    private func eventRow(_ event: CalendarEvent) -> NSView {
        let button = RowButton(target: self, action: #selector(openEvent))
        eventByButton[ObjectIdentifier(button)] = event
        let row: NSView
        if event.isAllDay {
            let badge = UI.roundedBox(fill: event.color, radius: 999)
            let label = UI.label(L("全天"), font: Typography.sans(10.5, .medium), color: Palette.rgb(0xFFFFFF), align: .center)
            label.translatesAutoresizingMaskIntoConstraints = false
            badge.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: 7),
                label.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -7),
                label.topAnchor.constraint(equalTo: badge.topAnchor, constant: 3),
                label.bottomAnchor.constraint(equalTo: badge.bottomAnchor, constant: -3)
            ])
            let title = UI.label(event.title, font: Typography.sans(13.5), color: Palette.eventInk)
            // The trailing spacer absorbs the slack; without it the stack
            // centers its content and a short all-day title drifts inward
            // while a long one still looks left-aligned.
            let line = NSStackView(views: [badge, title, spacer()])
            line.orientation = .horizontal
            line.alignment = .centerY
            line.spacing = 8
            row = line
        } else {
            let bar = UI.roundedBox(fill: event.color, radius: 999)
            bar.widthAnchor.constraint(equalToConstant: 3).isActive = true
            bar.heightAnchor.constraint(equalToConstant: 30).isActive = true
            let time = UI.label(event.timeRangeText(use24Hour: use24Hour), font: Typography.mono(11), color: Palette.eventInk2)
            let title = UI.label(event.title, font: Typography.sans(13.5), color: Palette.eventInk)
            title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            let text = NSStackView(views: [time, title])
            text.orientation = .vertical
            text.spacing = 1
            text.alignment = .leading
            let pieces: [NSView] = event.videoURL == nil ? [bar, text, spacer()] : [bar, text, spacer(), glyph("video.fill")]
            let line = NSStackView(views: pieces)
            line.orientation = .horizontal
            line.alignment = .centerY
            line.spacing = 8
            row = line
        }
        let padded = NSStackView(views: [row])
        padded.orientation = .vertical
        padded.edgeInsets = NSEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        button.addContentView(padded)
        return button
    }

    private func pastToggle() -> NSView {
        let icon = glyph("clock")
        let label = UI.label(L("过往日程"), font: Typography.sans(12), color: Palette.eventInk3)
        let chevron = glyph(pastExpanded ? "chevron.down" : "chevron.right")
        let row = NSStackView(views: [icon, label, spacer(), chevron])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 6
        row.edgeInsets = NSEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        let button = RowButton(target: self, action: #selector(togglePast))
        button.addContentView(row)
        return button
    }

    private func glyph(_ symbol: String) -> NSImageView {
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: symbol)?
            .withSymbolConfiguration(.init(pointSize: 11, weight: .medium))
        let view = NSImageView(image: image ?? NSImage())
        view.contentTintColor = Palette.eventInk2
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: 14).isActive = true
        return view
    }

    private func spacer() -> NSView {
        let view = NSView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return view
    }

    private var isToday: Bool {
        let parts = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: now)
        return selectedDate.year == parts.year && selectedDate.month == parts.month && selectedDate.day == parts.day
    }

    private var weekdayIndex: Int {
        Calendar(identifier: .gregorian).component(.weekday, from: selectedDate.noonDate) - 1
    }

    private func longDate() -> String {
        switch Loc.language {
        case .zh, .zhHant: return String(selectedDate.year) + "年" + String(selectedDate.month) + "月" + String(selectedDate.day) + "日"
        // No weekday here in any language: the bold slot to the left already
        // carries it (or 今天/Today), and spelling it twice both read wrong and
        // truncated the date in the 300pt Luna panel.
        case .en: return Loc.monthShort(selectedDate.month) + " " + String(selectedDate.day)
        case .th: return String(selectedDate.day) + " " + Loc.monthShort(selectedDate.month)
        }
    }

    @objc private func togglePast() {
        pastExpanded.toggle()
        pastEventsView?.isHidden = !pastExpanded
        // The height constraint tracks the document view, so expanding or
        // collapsing the past section resizes the panel on its own.
        scrollView?.layoutSubtreeIfNeeded()
    }

    @objc private func openEvent(_ sender: RowButton) {
        guard let event = eventByButton[ObjectIdentifier(sender)] else { return }
        onOpenEvent(event)
    }

    @objc private func openMoon() { onOpenMoon(selectedDate) }

    @objc private func requestAccess() { onRequestAccess() }
}
