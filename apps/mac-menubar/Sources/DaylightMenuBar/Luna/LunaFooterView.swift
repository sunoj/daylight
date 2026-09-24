// Dark footer showing the nearest upcoming system-calendar event.
// Exports: LunaFooterView
// Deps: AppKit, CalendarEvent, Components, DesignSystem, NextEventFormatter

import AppKit

final class LunaFooterView: NSView {
    private let events: [CalendarEvent]
    private let now: Date
    private let onOpenSettings: () -> Void
    private let onOpenEvent: (CalendarEvent) -> Void
    /// Absent in the period picker, which has no day to write an entry against.
    private let onNewThought: (() -> Void)?
    private var eventByButton: [ObjectIdentifier: CalendarEvent] = [:]

    init(
        events: [CalendarEvent],
        now: Date = Date(),
        onOpenSettings: @escaping () -> Void,
        onOpenEvent: @escaping (CalendarEvent) -> Void,
        onNewThought: (() -> Void)?
    ) {
        self.events = events
        self.now = now
        self.onOpenSettings = onOpenSettings
        self.onOpenEvent = onOpenEvent
        self.onNewThought = onNewThought
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        render()
    }

    required init?(coder: NSCoder) { nil }

    private func render() {
        let background = UI.roundedBox(fill: Palette.popoverEventFooter, radius: 0)
        addSubview(background)
        NSLayoutConstraint.activate([
            background.topAnchor.constraint(equalTo: topAnchor),
            background.leadingAnchor.constraint(equalTo: leadingAnchor),
            background.trailingAnchor.constraint(equalTo: trailingAnchor),
            background.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        let content = NSStackView()
        content.orientation = .vertical
        // NSStackView defaults to 8pt. Left unset, the hairline and the row sat
        // 8pt apart, so the footer had 19pt above its content and 10pt below.
        content.spacing = 0
        content.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(content)
        let line = UI.roundedBox(fill: Palette.eventLine, radius: 0)
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true
        content.addArrangedSubview(line)
        var pieces: [NSView] = [settingsButton(), nextEventView() ?? spacer(), spacer()]
        if onNewThought != nil { pieces.append(newThoughtButton()) }
        let row = NSStackView(views: pieces)
        row.orientation = .horizontal
        row.spacing = 10
        row.alignment = .centerY
        row.edgeInsets = NSEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        content.addArrangedSubview(row)
        line.widthAnchor.constraint(equalTo: content.widthAnchor).isActive = true
        row.widthAnchor.constraint(equalTo: content.widthAnchor).isActive = true
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: background.topAnchor),
            content.leadingAnchor.constraint(equalTo: background.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: background.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: background.bottomAnchor)
        ])
    }

    private func newThoughtButton() -> NSView {
        let button = RowButton(target: self, action: #selector(openNewThought))
        button.widthAnchor.constraint(equalToConstant: 24).isActive = true
        button.heightAnchor.constraint(equalToConstant: 24).isActive = true
        button.toolTip = L("新建日记")
        button.addContentView(glyph("square.and.pencil"))
        return button
    }

    private func settingsButton() -> NSView {
        let button = RowButton(target: self, action: #selector(openSettings))
        button.widthAnchor.constraint(equalToConstant: 24).isActive = true
        button.heightAnchor.constraint(equalToConstant: 24).isActive = true
        button.addContentView(glyph("gearshape"))
        return button
    }

    private func nextEventView() -> NSView? {
        guard let event = NextEventFormatter.next(in: events, now: now), let relative = NextEventFormatter.relative(to: event.start, from: now) else {
            return nil
        }
        let button = RowButton(target: self, action: #selector(openEvent))
        eventByButton[ObjectIdentifier(button)] = event
        let relativeLabel = UI.label(relative, font: Typography.sans(12), color: Palette.eventInk2)
        let separator = UI.label(" – ", font: Typography.sans(12), color: Palette.eventInk2)
        let title = UI.label(event.title, font: Typography.sans(12), color: Palette.eventInk)
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        var views: [NSView] = [relativeLabel, separator, title]
        if event.videoURL != nil { views.append(glyph("video.fill")) }
        let row = NSStackView(views: views)
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 0
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

    @objc private func openSettings() { onOpenSettings() }

    @objc private func openNewThought() { onNewThought?() }

    @objc private func openEvent(_ sender: RowButton) {
        guard let event = eventByButton[ObjectIdentifier(sender)] else { return }
        onOpenEvent(event)
    }
}
