// Sol-styled system-calendar event rows for the Sol calendar screen.
// Exports: CalendarEventRowButton, SolCalendarEventRow
// Deps: AppKit, CalendarEvent, Components, DesignSystem

import AppKit

class CalendarEventRowButton: RowButton {
    let event: CalendarEvent

    init(event: CalendarEvent, target: AnyObject?, action: Selector) {
        self.event = event
        super.init(target: target, action: action)
    }

    required init?(coder: NSCoder) { nil }
}

/// Shared Sol-styled, clickable system-calendar event row.
final class SolCalendarEventRow: CalendarEventRowButton {
    init(event: CalendarEvent, use24Hour: Bool, target: AnyObject?, action: Selector) {
        super.init(event: event, target: target, action: action)
        addContentView(content(event: event, use24Hour: use24Hour))
    }

    required init?(coder: NSCoder) { nil }

    private func content(event: CalendarEvent, use24Hour: Bool) -> NSView {
        let marker = UI.roundedBox(fill: event.color, radius: 999)
        marker.widthAnchor.constraint(equalToConstant: 4).isActive = true
        marker.heightAnchor.constraint(equalToConstant: 26).isActive = true
        let time = UI.label(
            event.isAllDay ? L("全天") : event.timeRangeText(use24Hour: use24Hour),
            font: Typography.mono(11),
            color: Palette.ink3
        )
        time.widthAnchor.constraint(greaterThanOrEqualToConstant: 62).isActive = true
        let title = UI.label(event.title, font: Typography.sans(13), color: Palette.ink)
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let text = NSStackView(views: [time, title])
        text.orientation = .vertical
        text.spacing = 1
        text.alignment = .leading
        var views: [NSView] = [marker, text, flexSpacer()]
        if event.videoURL != nil { views.append(videoGlyph()) }
        let row = NSStackView(views: views)
        row.orientation = .horizontal
        row.spacing = 9
        row.alignment = .centerY
        row.edgeInsets = NSEdgeInsets(top: 7, left: 10, bottom: 7, right: 10)
        return row
    }

    private func flexSpacer() -> NSView {
        let view = NSView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return view
    }

    private func videoGlyph() -> NSImageView {
        let image = NSImage(systemSymbolName: "video.fill", accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: 11, weight: .medium))
        let view = NSImageView(image: image ?? NSImage())
        view.contentTintColor = Palette.ink3
        view.widthAnchor.constraint(equalToConstant: 14).isActive = true
        return view
    }
}
