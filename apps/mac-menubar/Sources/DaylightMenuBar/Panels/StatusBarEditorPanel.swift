// Status bar editor — reorderable enabled segments plus an add list.
// Exports: StatusBarEditorPanel
// Deps: AppKit, DaylightStore, DesignSystem, Components, StatusBarRenderer

import AppKit

final class SegmentButton: RowButton {
    var segmentId: String = ""
}

final class StatusBarEditorPanel: NSStackView {
    private let store: DaylightStore
    private let calendarModel: CalendarModel
    private let provider = StatusTitleProvider()
    private let onDataChanged: () -> Void
    private let onNeedsRender: () -> Void
    private let onClose: () -> Void

    init(
        store: DaylightStore,
        calendarModel: CalendarModel,
        onDataChanged: @escaping () -> Void,
        onNeedsRender: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.store = store
        self.calendarModel = calendarModel
        self.onDataChanged = onDataChanged
        self.onNeedsRender = onNeedsRender
        self.onClose = onClose
        super.init(frame: .zero)
        orientation = .vertical
        spacing = 10
        alignment = .leading
        edgeInsets = NSEdgeInsets(top: 4, left: 4, bottom: 8, right: 4)
        render()
    }

    required init?(coder: NSCoder) { nil }

    private func render() {
        let enabled = store.settings().statusSegments
        let available = StatusSegmentKind.allCases.map(\.rawValue).filter { !enabled.contains($0) }
        addFullWidth(header())
        addFullWidth(preview(enabled))
        addFullWidth(UI.sectionHeader(L("已启用 · 上下调整顺序")))
        addFullWidth(enabledGroup(enabled))
        if !available.isEmpty {
            addFullWidth(UI.sectionHeader(L("可添加")))
            addFullWidth(availableGroup(available))
        }
        if enabled.contains("time") {
            addFullWidth(UI.sectionHeader(L("格式")))
            addFullWidth(formatGroup())
        }
    }

    private func addFullWidth(_ view: NSView) {
        addArrangedSubview(view)
        view.widthAnchor.constraint(equalTo: widthAnchor, constant: -8).isActive = true
    }

    private func header() -> NSView {
        let title = UI.label(L("状态栏"), font: Typography.sans(20, .semibold), color: Palette.ink)
        let back = SegmentButton(target: self, action: #selector(close))
        let tile = closeTile()
        back.addContentView(tile)
        let row = NSStackView(views: [title, spacer(), back])
        row.orientation = .horizontal
        row.spacing = 8
        row.edgeInsets = NSEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        return row
    }

    private func preview(_ enabled: [String]) -> NSView {
        let segments = provider.segments(today: calendarModel.today(), settings: store.settings())
        let strip = UI.roundedBox(fill: Palette.surface2, radius: Metrics.tileRadius, border: Palette.line)
        strip.heightAnchor.constraint(equalToConstant: 40).isActive = true
        let content: NSView
        if let image = StatusBarRenderer.image(for: segments) {
            content = NSImageView(image: tintedImage(image))
        } else {
            content = UI.label(L("状态栏为空"), font: Typography.sans(12), color: Palette.ink3)
        }
        content.translatesAutoresizingMaskIntoConstraints = false
        strip.addSubview(content)
        NSLayoutConstraint.activate([
            content.centerYAnchor.constraint(equalTo: strip.centerYAnchor),
            content.leadingAnchor.constraint(equalTo: strip.leadingAnchor, constant: 14)
        ])
        return strip
    }

    private func tintedImage(_ template: NSImage) -> NSImage {
        let image = NSImage(size: template.size, flipped: false) { rect in
            Palette.ink.set()
            rect.fill()
            template.draw(in: rect, from: .zero, operation: .destinationIn, fraction: 1)
            return true
        }
        return image
    }

    private func enabledGroup(_ enabled: [String]) -> NSView {
        let rows: [NSView] = enabled.enumerated().map { index, id in
            enabledRow(id: id, index: index, count: enabled.count)
        }
        return groupCard(rows)
    }

    private func availableGroup(_ available: [String]) -> NSView {
        groupCard(available.map { availableRow(id: $0) })
    }

    private func enabledRow(id: String, index: Int, count: Int) -> NSView {
        let name = UI.label(displayName(id), font: Typography.sans(14.5), color: Palette.ink)
        let up = iconButton("chevron.up", id: id, action: #selector(moveSegmentUp), enabled: index > 0)
        let down = iconButton("chevron.down", id: id, action: #selector(moveSegmentDown), enabled: index < count - 1)
        let remove = iconButton("minus.circle", id: id, action: #selector(removeSegment), enabled: true)
        let row = NSStackView(views: [orderGlyph(), name, spacer(), up, down, remove])
        row.orientation = .horizontal
        row.spacing = 10
        row.alignment = .centerY
        row.edgeInsets = NSEdgeInsets(top: 9, left: 14, bottom: 9, right: 12)
        return row
    }

    private func availableRow(id: String) -> NSView {
        let name = UI.label(displayName(id), font: Typography.sans(14.5), color: Palette.ink2)
        let add = iconButton("plus.circle", id: id, action: #selector(addSegment), enabled: true)
        let row = NSStackView(views: [name, spacer(), add])
        row.orientation = .horizontal
        row.spacing = 10
        row.alignment = .centerY
        row.edgeInsets = NSEdgeInsets(top: 9, left: 14, bottom: 9, right: 12)
        return row
    }

    private func formatGroup() -> NSView {
        let name = UI.label(L("24 小时制"), font: Typography.sans(14.5), color: Palette.ink)
        let toggle = PillToggle(isOn: store.settings().statusUse24HourTime, target: self, action: #selector(toggle24Hour))
        let row = NSStackView(views: [name, spacer(), toggle])
        row.orientation = .horizontal
        row.spacing = 10
        row.alignment = .centerY
        row.edgeInsets = NSEdgeInsets(top: 9, left: 14, bottom: 9, right: 14)
        // Whole-row hit area, same as the settings toggle rows.
        let click = ClickView()
        click.onClick = { [weak toggle] in toggle?.activate() }
        click.addContentView(row)
        return groupCard([click])
    }

    private func groupCard(_ rows: [NSView]) -> NSView {
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

    private func orderGlyph() -> NSView {
        let image = NSImage(systemSymbolName: "line.3.horizontal", accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: 12, weight: .regular))
        let view = NSImageView(image: image ?? NSImage())
        view.contentTintColor = Palette.ink4
        return view
    }

    private func iconButton(_ symbol: String, id: String, action: Selector, enabled: Bool) -> NSView {
        let button = SegmentButton(target: self, action: action)
        button.segmentId = id
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: symbol)?
            .withSymbolConfiguration(.init(pointSize: 16, weight: .regular))
        let view = NSImageView(image: image ?? NSImage())
        view.contentTintColor = enabled ? Palette.ink2 : Palette.ink4
        button.addContentView(view)
        button.isEnabled = enabled
        button.alphaValue = enabled ? 1 : 0.4
        button.widthAnchor.constraint(equalToConstant: 20).isActive = true
        return button
    }

    private func closeTile() -> NSView {
        let tile = UI.roundedBox(fill: Palette.surface2, radius: 14)
        tile.widthAnchor.constraint(equalToConstant: 28).isActive = true
        tile.heightAnchor.constraint(equalToConstant: 28).isActive = true
        let glyph = NSImageView(image: NSImage(systemSymbolName: "chevron.left", accessibilityDescription: "Back") ?? NSImage())
        glyph.contentTintColor = Palette.ink2
        glyph.translatesAutoresizingMaskIntoConstraints = false
        tile.addSubview(glyph)
        NSLayoutConstraint.activate([
            glyph.centerXAnchor.constraint(equalTo: tile.centerXAnchor),
            glyph.centerYAnchor.constraint(equalTo: tile.centerYAnchor)
        ])
        return tile
    }

    private func spacer() -> NSView {
        let view = NSView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return view
    }

    private func displayName(_ id: String) -> String {
        StatusSegmentKind(rawValue: id)?.displayName ?? id
    }

    // MARK: Actions

    @objc private func close() { onClose() }

    @objc private func moveSegmentUp(_ sender: SegmentButton) { move(sender.segmentId, by: -1) }
    @objc private func moveSegmentDown(_ sender: SegmentButton) { move(sender.segmentId, by: 1) }

    private func move(_ id: String, by offset: Int) {
        var segments = store.settings().statusSegments
        guard let index = segments.firstIndex(of: id) else { return }
        let target = index + offset
        guard target >= 0, target < segments.count else { return }
        segments.swapAt(index, target)
        commit(segments)
    }

    @objc private func removeSegment(_ sender: SegmentButton) {
        commit(store.settings().statusSegments.filter { $0 != sender.segmentId })
    }

    @objc private func addSegment(_ sender: SegmentButton) {
        var segments = store.settings().statusSegments
        guard !segments.contains(sender.segmentId) else { return }
        segments.append(sender.segmentId)
        commit(segments)
    }

    @objc private func toggle24Hour(_ sender: PillToggle) {
        var settings = store.settings()
        settings.statusUse24HourTime = sender.isOn
        store.saveSettings(settings)
        onDataChanged()
        onNeedsRender()
    }

    private func commit(_ segments: [String]) {
        var settings = store.settings()
        settings.statusSegments = segments
        store.saveSettings(settings)
        onDataChanged()
        onNeedsRender()
    }
}
