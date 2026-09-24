// Low-level AppKit view primitives for shared UI construction.
// Exports: RowButton, ClickView, LayerColorView, NSView.cg(_:)
// Deps: AppKit

import AppKit

/// A transparent click target that hosts arbitrary content (row-wide tap).
class RowButton: NSControl {
    var showsHoverFeedback = true
    private var isHovering = false
    private var trackingArea: NSTrackingArea?

    init(target: AnyObject?, action: Selector) {
        super.init(frame: .zero)
        self.target = target
        self.action = action
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) { nil }

    func addContentView(_ view: NSView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    override var isEnabled: Bool {
        didSet {
            alphaValue = isEnabled ? (isHovering ? 0.72 : 1) : 0.35
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea { removeTrackingArea(trackingArea) }
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect]
        let area = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        isHovering = true
        applyHoverAlpha()
    }

    override func mouseExited(with event: NSEvent) {
        isHovering = false
        applyHoverAlpha()
    }

    private func applyHoverAlpha() {
        guard showsHoverFeedback, isEnabled, !Motion.isReduced else { return }
        let target: CGFloat = isHovering ? 0.72 : 1
        Motion.run(duration: Motion.micro, timing: Motion.easeOut) {
            self.animator().alphaValue = target
        }
    }

    override func mouseDown(with event: NSEvent) {
        guard isEnabled else { return }
        sendAction(action, to: target)
    }

    override func resetCursorRects() {
        guard isEnabled else { return }
        addCursorRect(bounds, cursor: .pointingHand)
    }
}

/// A minimal view that reports clicks through a closure.
final class ClickView: NSView {
    var onClick: (() -> Void)?
    override func mouseDown(with event: NSEvent) { onClick?() }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }

    /// Fill this view with `view` so the whole area becomes the hit target.
    func addContentView(_ view: NSView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}


extension NSView {
    /// Resolves an NSColor to a CGColor using THIS view's effective appearance,
    /// so layer background colors stay correct in dark mode. Plain `.cgColor`
    /// uses the thread's current appearance instead, which is often wrong.
    func cg(_ color: NSColor) -> CGColor {
        var resolved = color.cgColor
        effectiveAppearance.performAsCurrentDrawingAppearance { resolved = color.cgColor }
        return resolved
    }
}

/// NSView whose fill and border track appearance changes (dynamic colors).
/// Uses `updateLayer`, which runs with the view's effective appearance current.
final class LayerColorView: NSView {
    var fillColor: NSColor = .clear { didSet { needsDisplay = true } }
    var borderColorValue: NSColor? { didSet { needsDisplay = true } }
    var borderWidthValue: CGFloat = 0 { didSet { needsDisplay = true } }

    /// Requested radius. A huge value (999) is the pill idiom — "round the ends
    /// fully" — so it is clamped to half the shorter side rather than passed to
    /// CoreAnimation as-is. An unclamped radius larger than half the bounds is
    /// undefined: a 344x44 pill with cornerRadius 999 silently drew NOTHING,
    /// which is why the location prompt came up with no buttons. Squares such as
    /// the 28x28 close button happened to survive it, so the idiom looked fine.
    var cornerRadiusValue: CGFloat = 0 { didSet { needsDisplay = true } }

    override var wantsUpdateLayer: Bool { true }

    override func updateLayer() {
        layer?.backgroundColor = cg(fillColor)
        layer?.isOpaque = fillColor.alphaComponent >= 1
        layer?.borderColor = borderColorValue.map(cg)
        layer?.borderWidth = borderWidthValue
        layer?.cornerRadius = min(cornerRadiusValue, min(bounds.width, bounds.height) / 2)
    }

    override func layout() {
        super.layout()
        // Bounds drive the clamp, so re-apply whenever they change.
        needsDisplay = true
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }
}
