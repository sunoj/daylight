// Row builders for the legal-holiday subscription panel.
// Exports: HolidaySubscriptionPanel row builders
// Deps: AppKit, DesignSystem, Components, HolidayService

import AppKit

extension HolidaySubscriptionPanel {
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

    func sourceRow(_ source: HolidaySource, subscription: HolidaySubscription?) -> NSView {
        let selected = subscription != nil
        let title = UI.label(L(source.name), font: Typography.sans(14.5, selected ? .medium : .regular), color: Palette.ink)
        let titleView: NSView
        if !source.detail.isEmpty && (selected || source.id == "custom") {
            let sub = UI.label(L(source.detail), font: Typography.mono(10.5), color: Palette.ink4)
            let col = NSStackView(views: [title, sub])
            col.orientation = .vertical
            col.spacing = 2
            col.alignment = .leading
            titleView = col
        } else {
            titleView = title
        }
        var views: [NSView] = [checkbox(selected), titleView, spacer()]
        if let subscription {
            views.append(colorSwatch(subscription))
        }
        let count = HolidaySourceCountFormatter.string(for: source.count)
        views.append(count.isEmpty ? symbol("chevron.right", Palette.ink3) : UI.label(count, font: Typography.mono(11), color: selected ? Palette.ink3 : Palette.ink4))
        let row = NSStackView(views: views)
        row.orientation = .horizontal
        row.spacing = 12
        row.alignment = .centerY
        row.edgeInsets = NSEdgeInsets(top: 11, left: 14, bottom: 11, right: 14)
        let button = SourceButton(target: self, action: #selector(toggleSource))
        button.sourceId = source.id
        button.addContentView(UI.roundedBox(fill: selected ? Palette.surface2 : .clear, radius: 0).wrapping(row))
        return button
    }

    func checkbox(_ selected: Bool) -> NSView {
        let box = UI.roundedBox(fill: selected ? Palette.ink : .clear, radius: 4, border: selected ? Palette.ink : Palette.line2, borderWidth: 1.5)
        box.widthAnchor.constraint(equalToConstant: 20).isActive = true
        box.heightAnchor.constraint(equalToConstant: 20).isActive = true
        guard selected else { return box }
        let check = symbol("checkmark", Palette.accentInk)
        check.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(check)
        NSLayoutConstraint.activate([
            check.centerXAnchor.constraint(equalTo: box.centerXAnchor),
            check.centerYAnchor.constraint(equalTo: box.centerYAnchor)
        ])
        return box
    }

    func colorSwatch(_ subscription: HolidaySubscription) -> NSView {
        let button = ColorButton(target: self, action: #selector(cycleColor))
        button.subscriptionId = subscription.id
        button.toolTip = colorName(subscription.colorId)
        let outer = UI.roundedBox(fill: .clear, radius: 7, border: Palette.line2)
        outer.widthAnchor.constraint(equalToConstant: 22).isActive = true
        outer.heightAnchor.constraint(equalToConstant: 22).isActive = true
        let dot = UI.roundedBox(fill: Palette.holidayColor(subscription.colorId), radius: 999)
        dot.translatesAutoresizingMaskIntoConstraints = false
        outer.addSubview(dot)
        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: 12),
            dot.heightAnchor.constraint(equalToConstant: 12),
            dot.centerXAnchor.constraint(equalTo: outer.centerXAnchor),
            dot.centerYAnchor.constraint(equalTo: outer.centerYAnchor)
        ])
        button.addContentView(outer)
        return button
    }

    func nameRow(_ value: String) -> NSView {
        nameField.stringValue = value
        nameField.placeholderString = L("留空则自动读取")
        nameField.font = Typography.sans(13)
        nameField.textColor = Palette.ink
        nameField.isBordered = false
        nameField.drawsBackground = false
        nameField.focusRingType = .none
        nameField.target = self
        nameField.action = #selector(commitName)
        let title = UI.label(L("名称"), font: Typography.sans(14), color: Palette.ink2)
        let fieldBox = UI.roundedBox(fill: Palette.surface2, radius: 10, border: Palette.line)
        nameField.translatesAutoresizingMaskIntoConstraints = false
        fieldBox.addSubview(nameField)
        NSLayoutConstraint.activate([
            fieldBox.heightAnchor.constraint(equalToConstant: 42),
            nameField.leadingAnchor.constraint(equalTo: fieldBox.leadingAnchor, constant: 12),
            nameField.trailingAnchor.constraint(equalTo: fieldBox.trailingAnchor, constant: -12),
            nameField.centerYAnchor.constraint(equalTo: fieldBox.centerYAnchor)
        ])
        let row = NSStackView(views: [title, fieldBox])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 10
        title.widthAnchor.constraint(equalToConstant: 38).isActive = true
        fieldBox.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return row
    }

    func urlRow(_ value: String) -> NSView {
        urlField.stringValue = value
        urlField.placeholderString = "https://…/holidays.ics"
        urlField.font = Typography.mono(12)
        urlField.textColor = Palette.ink
        urlField.isBordered = false
        urlField.drawsBackground = false
        urlField.focusRingType = .none
        urlField.target = self
        urlField.action = #selector(commitURL)
        let fieldBox = UI.roundedBox(fill: Palette.surface2, radius: 10, border: Palette.line)
        urlField.translatesAutoresizingMaskIntoConstraints = false
        fieldBox.addSubview(urlField)
        NSLayoutConstraint.activate([
            fieldBox.heightAnchor.constraint(equalToConstant: 42),
            urlField.leadingAnchor.constraint(equalTo: fieldBox.leadingAnchor, constant: 12),
            urlField.trailingAnchor.constraint(equalTo: fieldBox.trailingAnchor, constant: -12),
            urlField.centerYAnchor.constraint(equalTo: fieldBox.centerYAnchor)
        ])
        let paste = RowButton(target: self, action: #selector(pasteURL))
        let pasteBox = UI.roundedBox(fill: Palette.surface2, radius: 10, border: Palette.line)
        let pasteLabel = UI.label(L("粘贴"), font: Typography.sans(13), color: Palette.ink2, align: .center)
        pasteLabel.translatesAutoresizingMaskIntoConstraints = false
        pasteBox.addSubview(pasteLabel)
        NSLayoutConstraint.activate([
            pasteLabel.centerXAnchor.constraint(equalTo: pasteBox.centerXAnchor),
            pasteLabel.centerYAnchor.constraint(equalTo: pasteBox.centerYAnchor),
            pasteLabel.leadingAnchor.constraint(equalTo: pasteBox.leadingAnchor, constant: 14),
            pasteLabel.trailingAnchor.constraint(equalTo: pasteBox.trailingAnchor, constant: -14)
        ])
        paste.addContentView(pasteBox)
        paste.heightAnchor.constraint(equalToConstant: 42).isActive = true
        let row = NSStackView(views: [fieldBox, paste])
        row.orientation = .horizontal
        row.spacing = 8
        fieldBox.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return row
    }

    func updateRow(_ weekly: Bool) -> NSView {
        let title = UI.label(L("自动更新"), font: Typography.sans(14.5), color: Palette.ink)
        let segmented = SegmentedControl(items: [L("每天"), L("每周")], selectedIndex: weekly ? 1 : 0) { [weak self] index in
            self?.update { $0.holidayUpdateWeekly = index == 1 }
        }
        let row = NSStackView(views: [title, spacer(), segmented])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.edgeInsets = NSEdgeInsets(top: 9, left: 14, bottom: 9, right: 12)
        return row
    }

    func subscribeButton() -> NSView {
        UI.filledButton(L("订阅并标注"), target: self, action: #selector(subscribe), height: 44, radius: 22)
    }

    func noteRow() -> NSView {
        let row = NSStackView(views: [spacer(), noteLabel, spacer()])
        row.orientation = .horizontal
        row.edgeInsets = NSEdgeInsets(top: 2, left: 4, bottom: 4, right: 4)
        return row
    }

    func symbol(_ name: String, _ color: NSColor) -> NSImageView {
        let view = NSImageView(image: NSImage(systemSymbolName: name, accessibilityDescription: name) ?? NSImage())
        view.contentTintColor = color
        return view
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

    func spacer() -> NSView {
        let view = NSView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return view
    }

    private func colorName(_ id: String) -> String {
        switch id {
        case "stone": return L("石蓝")
        case "olive": return L("橄榄")
        case "amber": return L("琥珀")
        case "green": return L("绿")
        default: return L("铁锈")
        }
    }
}
