// Solar-term icon view and its shape/lookup surface.
// Exports: SolarTermIconArt, SolarTermIconView
// Deps: AppKit, DesignSystem, SolarTermIconGlyphs

import AppKit

struct SolarTermIconShape {
    enum Mode { case stroke, fill }
    let path: NSBezierPath
    let mode: Mode
    var lineWidth: CGFloat? = nil
    var opacity: CGFloat = 1
    var tone: SolarTermIconTone = .inherit
}

enum SolarTermIconArt {
    static let termNames = [
        "小寒", "大寒", "立春", "雨水", "惊蛰", "春分", "清明", "谷雨",
        "立夏", "小满", "芒种", "夏至", "小暑", "大暑", "立秋", "处暑",
        "白露", "秋分", "寒露", "霜降", "立冬", "小雪", "大雪", "冬至"
    ]

    static func path(for term: String, in rect: CGRect = CGRect(x: 0, y: 0, width: 24, height: 24)) -> NSBezierPath {
        let combined = NSBezierPath()
        shapes(for: term, in: rect).forEach { combined.append($0.path) }
        return combined
    }

    static func shapes(for term: String, in rect: CGRect, variant: SolarTermIconVariant = .small) -> [SolarTermIconShape] {
        SolarTermIconGlyphs.shapes(for: term, in: rect, variant: variant)
    }
}

final class SolarTermIconView: NSView {
    var term: String { didSet { needsDisplay = true; updateAccessibility() } }
    var tintColor: NSColor = Palette.ink2 { didSet { needsDisplay = true } }
    let variant: SolarTermIconVariant

    init(term: String = "", variant: SolarTermIconVariant = .small, frame frameRect: NSRect = NSRect(x: 0, y: 0, width: 24, height: 24)) {
        self.term = term
        self.variant = variant
        super.init(frame: frameRect)
        translatesAutoresizingMaskIntoConstraints = false
        updateAccessibility()
    }

    required init?(coder: NSCoder) { nil }

    override var intrinsicContentSize: NSSize {
        let size: CGFloat = variant == .small ? 24 : 48
        return NSSize(width: size, height: size)
    }

    private func updateAccessibility() {
        toolTip = term
        setAccessibilityElement(true)
        setAccessibilityRole(.image)
        setAccessibilityLabel(term)
    }

    override func draw(_ dirtyRect: NSRect) {
        let side = min(bounds.width, bounds.height)
        let rect = CGRect(x: bounds.midX - side / 2, y: bounds.midY - side / 2, width: side, height: side)
        effectiveAppearance.performAsCurrentDrawingAppearance {
            for shape in SolarTermIconArt.shapes(for: term, in: rect, variant: variant) {
                let dark = effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                let base = SolarTermIconPalette.color(for: shape.tone, dark: dark, fallback: tintColor)
                let color = base.withAlphaComponent(base.alphaComponent * shape.opacity)
                color.setStroke()
                color.setFill()
                shape.path.lineWidth = (shape.lineWidth ?? (variant == .small ? 1.6 : 1)) * side / 24
                shape.path.lineCapStyle = .round
                shape.path.lineJoinStyle = .round
                switch shape.mode {
                case .stroke: shape.path.stroke()
                case .fill: shape.path.fill()
                }
            }
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }
}
