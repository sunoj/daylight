// Static AppKit factories for the plain design system.
// Exports: UI, NSView.wrapping
// Deps: AppKit, DesignSystem, ViewPrimitives

import AppKit

/// Static factories for the shared visual vocabulary.
enum UI {
    static func label(_ text: String, font: NSFont, color: NSColor, align: NSTextAlignment = .left, tracking: CGFloat = 0) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = font
        field.textColor = color
        field.alignment = align
        field.lineBreakMode = .byTruncatingTail
        if tracking != 0 {
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = align
            field.attributedStringValue = NSAttributedString(string: text, attributes: [
                .font: font, .foregroundColor: color, .kern: tracking, .paragraphStyle: paragraph
            ])
        }
        return field
    }

    /// Mono uppercase section header (e.g. "显示", "高级", "日程").
    static func sectionHeader(_ text: String, font: NSFont = Typography.mono(10.5, .medium), color: NSColor = Palette.ink3) -> NSView {
        label(text.uppercased(), font: font, color: color, tracking: 0.85)
    }

    /// Rounded surface-2 tile holding an SF Symbol, tinted ink-2.
    static func iconTile(symbol: String, size: CGFloat = 28, glyph: CGFloat = 15, fill: NSColor = Palette.surface2, glyphColor: NSColor = Palette.ink2) -> NSView {
        let tile = roundedBox(fill: fill, radius: 7)
        tile.widthAnchor.constraint(equalToConstant: size).isActive = true
        tile.heightAnchor.constraint(equalToConstant: size).isActive = true
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: glyph, weight: .regular))
        let view = NSImageView(image: image ?? NSImage())
        view.contentTintColor = glyphColor
        view.translatesAutoresizingMaskIntoConstraints = false
        tile.addSubview(view)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: tile.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: tile.centerYAnchor)
        ])
        return tile
    }

    /// A layer-backed rounded rectangle with a fill and optional hairline border.
    static func roundedBox(fill: NSColor, radius: CGFloat, border: NSColor? = nil, borderWidth: CGFloat = 1) -> NSView {
        let box = LayerColorView()
        box.wantsLayer = true
        box.fillColor = fill
        box.borderColorValue = border
        box.borderWidthValue = border == nil ? 0 : borderWidth
        // Set through the view, not the layer: it clamps to half the shorter side
        // once the bounds are known, so `radius: 999` reliably means "pill".
        box.cornerRadiusValue = radius
        box.translatesAutoresizingMaskIntoConstraints = false
        return box
    }

    /// A card: clear background, hairline border, rounded, wrapping content.
    static func card(_ content: NSView, radius: CGFloat = Metrics.cardRadius, padding: CGFloat = 0, fill: NSColor = .clear, border: NSColor = Palette.line) -> NSView {
        let box = roundedBox(fill: fill, radius: radius, border: border)
        content.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: box.topAnchor, constant: padding),
            content.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: padding),
            content.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -padding),
            content.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -padding)
        ])
        return box
    }

    static func hairline(color: NSColor = Palette.line) -> NSView {
        let line = roundedBox(fill: color, radius: 0)
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return line
    }

    /// Primary filled button (ink) with paper-colored text (e.g. 保存).
    /// `fill`/`titleColor` are overridable for the agenda panel, which stays dark
    /// in both appearances: the default ink there is near-black on near-black.
    static func filledButton(
        _ title: String,
        target: AnyObject?,
        action: Selector,
        height: CGFloat = 30,
        radius: CGFloat = Metrics.tileRadius,
        fill: NSColor = Palette.ink,
        titleColor: NSColor = Palette.accentInk
    ) -> NSView {
        let button = RowButton(target: target, action: action)
        let box = roundedBox(fill: fill, radius: radius)
        let label = label(title, font: Typography.sans(12.5, .medium), color: titleColor, align: .center)
        label.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(label)
        // The design's button hugs its label with 15pt either side (height 30,
        // padding 0 15px). Centring alone left the box with no intrinsic width, so
        // it stretched to fill whatever stack it was in. These are >= so a caller
        // that pins an explicit width still wins.
        // ==, not >=: >= only bounds the width below, and a RowButton has no intrinsic
        // size, so nothing pulled the box in and it stretched to fill its stack. At 999
        // an explicit width constraint (required) still wins — the calendar's 58pt 保存
        // and the full-width prompt pills rely on that.
        let leading = label.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 15)
        let trailing = box.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 15)
        leading.priority = .init(999)
        trailing.priority = .init(999)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: box.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            leading, trailing
        ])
        button.addContentView(box)
        button.heightAnchor.constraint(equalToConstant: height).isActive = true
        // The padding constraints above only set a lower bound, and a RowButton has no
        // intrinsic width — so next to a flexSpacer of equal hugging priority the stack
        // stretched the button instead of the spacer. Hug harder than the spacer (250)
        // so the slack goes there; an explicit width constraint still outranks this.
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return button
    }
}

extension NSView {
    /// Pins `content` inside the receiver with insets and returns the receiver.
    func wrapping(_ content: NSView) -> NSView {
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor),
            content.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.trailingAnchor.constraint(equalTo: trailingAnchor),
            content.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        return self
    }
}
