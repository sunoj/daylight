// Row builders for the system calendar settings screen.
// Exports: SystemCalendarPanel row builders
// Deps: AppKit, DesignSystem, Components

import AppKit

private final class HitTransparentView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

extension SystemCalendarPanel {
    func group(_ rows: [NSView]) -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 0
        stack.alignment = .leading
        for (index, row) in rows.enumerated() {
            stack.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
            if index < rows.count - 1 {
                let line = UI.hairline()
                stack.addArrangedSubview(line)
                line.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
            }
        }
        return UI.card(stack)
    }

    func toggleRow(_ icon: String, _ title: String, _ isOn: Bool, _ action: Selector, subtitle: String? = nil) -> NSView {
        let toggle = PillToggle(isOn: isOn, target: self, action: action)
        let row = baseRow(icon: icon, title: title, subtitle: subtitle, trailing: toggle)
        let click = ClickView()
        click.onClick = { [weak toggle] in toggle?.activate() }
        click.addContentView(row)
        return click
    }

    func calendarRow(_ calendar: SystemCalendarInfo, hiddenIds: [String]) -> NSView {
        let visible = SystemCalendarVisibility.isVisible(calendarId: calendar.id, hiddenIds: hiddenIds)
        let dot = UI.roundedBox(fill: calendar.color, radius: 999)
        dot.widthAnchor.constraint(equalToConstant: 10).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 10).isActive = true
        let title = UI.label(calendar.title, font: Typography.sans(14.5, visible ? .medium : .regular), color: Palette.ink)
        let toggle = PillToggle(isOn: visible, target: self, action: #selector(ignoreToggleInteraction))
        let toggleHost = HitTransparentView()
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggleHost.addSubview(toggle)
        NSLayoutConstraint.activate([
            toggle.topAnchor.constraint(equalTo: toggleHost.topAnchor),
            toggle.bottomAnchor.constraint(equalTo: toggleHost.bottomAnchor),
            toggle.trailingAnchor.constraint(equalTo: toggleHost.trailingAnchor),
            toggle.leadingAnchor.constraint(equalTo: toggleHost.leadingAnchor)
        ])
        let row = NSStackView(views: [dot, title, spacer(), toggleHost])
        row.orientation = .horizontal
        row.spacing = 12
        row.alignment = .centerY
        row.edgeInsets = NSEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        let button = CalendarToggleButton(target: self, action: #selector(toggleCalendar))
        button.calendarId = calendar.id
        button.addContentView(row)
        return button
    }

    func authorizationCard(canRequestAccess: Bool) -> NSView {
        let copy = UI.label(
            L("允许访问系统日历"),
            font: Typography.sans(12.5),
            color: Palette.ink3,
            align: .center
        )
        let action = canRequestAccess
            ? UI.filledButton(L("授权访问日历"), target: self, action: #selector(requestAccess), height: 30)
            : UI.filledButton(L("打开系统设置"), target: self, action: #selector(openSystemSettings), height: 30)
        let column = NSStackView(views: [copy, action])
        column.orientation = .vertical
        column.alignment = .centerX
        column.spacing = 10
        column.edgeInsets = NSEdgeInsets(top: 16, left: 14, bottom: 16, right: 14)
        return UI.card(column)
    }

    func header() -> NSView {
        let title = UI.label(L("系统日历"), font: Typography.sans(18, .semibold), color: Palette.ink)
        let sub = UI.label(L("选择要显示的日历"), font: Typography.sans(12), color: Palette.ink3)
        let left = NSStackView(views: [title, sub])
        left.orientation = .vertical
        left.spacing = 3
        left.alignment = .leading
        let row = NSStackView(views: [left, spacer(), closeButton()])
        row.orientation = .horizontal
        row.alignment = .top
        row.edgeInsets = NSEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        return row
    }

    func closeButton() -> NSView {
        let button = RowButton(target: self, action: #selector(close))
        let tile = UI.roundedBox(fill: Palette.surface2, radius: 14)
        tile.widthAnchor.constraint(equalToConstant: 28).isActive = true
        tile.heightAnchor.constraint(equalToConstant: 28).isActive = true
        let glyph = symbol("xmark", Palette.ink2)
        glyph.translatesAutoresizingMaskIntoConstraints = false
        tile.addSubview(glyph)
        NSLayoutConstraint.activate([
            glyph.centerXAnchor.constraint(equalTo: tile.centerXAnchor),
            glyph.centerYAnchor.constraint(equalTo: tile.centerYAnchor)
        ])
        button.addContentView(tile)
        return button
    }

    private func baseRow(icon: String, title: String, subtitle: String?, trailing: NSView) -> NSView {
        let titleLabel = UI.label(title, font: Typography.sans(14.5), color: Palette.ink)
        let titleView: NSView
        if let subtitle {
            let sub = UI.label(subtitle, font: Typography.sans(11.5), color: Palette.ink3)
            let column = NSStackView(views: [titleLabel, sub])
            column.orientation = .vertical
            column.spacing = 1
            column.alignment = .leading
            titleView = column
        } else {
            titleView = titleLabel
        }
        let row = NSStackView(views: [UI.iconTile(symbol: icon), titleView, spacer(), trailing])
        row.orientation = .horizontal
        row.spacing = 12
        row.alignment = .centerY
        row.edgeInsets = NSEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        return row
    }

    func symbol(_ name: String, _ color: NSColor) -> NSImageView {
        let view = NSImageView(image: NSImage(systemSymbolName: name, accessibilityDescription: name) ?? NSImage())
        view.contentTintColor = color
        return view
    }

    func spacer() -> NSView {
        let view = NSView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return view
    }
}
