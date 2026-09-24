// Holiday row rendering for Luna's selected-day agenda panel.
// Exports: EventListPanel row builders
// Deps: AppKit, HolidayDetailEntry, Components, DesignSystem

import AppKit

extension EventListPanel {
    func holidayRow(_ entry: HolidayDetailEntry) -> NSView {
        let badge = UI.roundedBox(fill: entry.badgeColor, radius: 999)
        let badgeLabel = UI.label(
            entry.typeLabel,
            font: Typography.sans(10.5, .medium),
            color: Palette.rgb(0xFFFFFF),
            align: .center
        )
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(badgeLabel)
        NSLayoutConstraint.activate([
            badgeLabel.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: 7),
            badgeLabel.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -7),
            badgeLabel.topAnchor.constraint(equalTo: badge.topAnchor, constant: 3),
            badgeLabel.bottomAnchor.constraint(equalTo: badge.bottomAnchor, constant: -3)
        ])
        let title = UI.label(entry.displayTitle, font: Typography.sans(13.5), color: Palette.eventInk)
        let subtitle = UI.label(entry.displaySubtitle, font: Typography.sans(11.5), color: Palette.eventInk2)
        subtitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let text = NSStackView(views: [title, subtitle])
        text.orientation = .vertical
        text.spacing = 1
        text.alignment = .leading
        let line = NSStackView(views: [badge, text, holidayRowSpacer()])
        line.orientation = .horizontal
        line.alignment = .centerY
        line.spacing = 8
        let padded = NSStackView(views: [line])
        padded.orientation = .vertical
        padded.edgeInsets = NSEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        return padded
    }

    private func holidayRowSpacer() -> NSView {
        let view = NSView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return view
    }
}
