// Settings row and grouped card builders for CalendarSettingsPanel.
// Exports: CalendarSettingsPanel row builders
// Deps: AppKit, DesignSystem, Components

import AppKit

extension CalendarSettingsPanel {
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
        // The whole row is the hit area: clicking the title/icon flips the
        // toggle. The pill consumes its own mouseDown, so no double fire.
        let toggle = PillToggle(isOn: isOn, target: self, action: action)
        let row = baseRow(icon: icon, title: title, subtitle: subtitle, trailing: toggle)
        let click = ClickView()
        click.onClick = { [weak toggle] in toggle?.activate() }
        click.addContentView(row)
        return click
    }

    func segmentedRow(_ icon: String, _ title: String, _ items: [String], _ selected: Int, _ onChange: @escaping (Int) -> Void) -> NSView {
        baseRow(icon: icon, title: title, subtitle: nil, trailing: SegmentedControl(items: items, selectedIndex: selected, onChange: onChange))
    }

    func selectRow(_ icon: String, _ title: String, _ value: String, _ action: Selector) -> NSView {
        trailingRow(icon, title, value, glyph: "chevron.down", action: action)
    }

    func calendarTypeName(_ rule: CalendarWeekRule) -> String {
        switch rule {
        case .iso8601: return L("国际标准")
        case .us: return L("美式")
        case .arabic: return L("阿拉伯")
        case .hebrew: return L("希伯来")
        }
    }

    @objc func openCalendarTypeMenu(_ sender: NSControl) {
        let current = store.settings().weekRule
        let menu = NSMenu()
        for rule in CalendarWeekRule.allCases {
            let item = NSMenuItem(
                title: calendarTypeName(rule),
                action: #selector(selectCalendarType(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = rule.rawValue
            item.state = rule == current ? .on : .off
            menu.addItem(item)
        }

        sender.layoutSubtreeIfNeeded()
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.minY), in: sender)
    }

    @objc private func selectCalendarType(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let rule = CalendarWeekRule(rawValue: rawValue) else { return }
        update { $0.calendarType = rule.rawValue }
    }

    func navRow(_ icon: String, _ title: String, _ value: String, _ action: Selector) -> NSView {
        trailingRow(icon, title, value, glyph: "chevron.right", action: action)
    }

    func actionRow(_ icon: String, _ title: String, _ value: String, _ action: Selector) -> NSView {
        trailingRow(icon, title, value, glyph: "chevron.right", action: action, valueMono: true)
    }

    func valueRow(_ icon: String, _ title: String, _ value: String) -> NSView {
        baseRow(icon: icon, title: title, subtitle: nil, trailing: UI.label(value, font: Typography.mono(12), color: Palette.ink3))
    }

    func destructiveActionRow(_ icon: String, _ title: String, _ action: Selector) -> NSView {
        let titleLabel = UI.label(title, font: Typography.sans(14.5), color: Palette.rust)
        let row = NSStackView(views: [UI.iconTile(symbol: icon, glyphColor: Palette.rust), titleLabel, spacer()])
        row.orientation = .horizontal
        row.spacing = 12
        row.alignment = .centerY
        row.edgeInsets = NSEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        let button = RowButton(target: self, action: action)
        button.addContentView(row)
        return button
    }

    private func trailingRow(_ icon: String, _ title: String, _ value: String, glyph: String, action: Selector, valueMono: Bool = false) -> NSView {
        let valueLabel = UI.label(value, font: valueMono ? Typography.mono(11) : Typography.sans(14), color: valueMono ? Palette.ink4 : Palette.ink2)
        let chevron = symbol(glyph, color: Palette.ink3)
        let control = NSStackView(views: [valueLabel, chevron])
        control.orientation = .horizontal
        control.spacing = 4
        // The whole row is the button, not just the value + chevron — the
        // title, icon, and whitespace all dispatch the same action.
        let button = RowButton(target: self, action: action)
        button.addContentView(baseRow(icon: icon, title: title, subtitle: nil, trailing: control))
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

    func symbol(_ name: String, color: NSColor) -> NSImageView {
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
