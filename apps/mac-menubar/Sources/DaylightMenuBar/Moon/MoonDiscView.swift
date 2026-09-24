// Flat monochrome moon disc — hairline circle + inked terminator arc.
// Exports: MoonArt, MoonDiscView
// Deps: AppKit, Core Graphics

import AppKit

/// Geometry helpers that reproduce the design's SVG moon: a light disc with
/// the illuminated portion drawn as a single ink shape. `fraction` is the
/// illuminated fraction 0…1; `waxing` picks the lit limb (right when waxing).
enum MoonArt {
    /// Closed path of the illuminated region within `rect`.
    static func illuminatedPath(fraction: Double, waxing: Bool, in rect: CGRect) -> CGPath {
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let fraction = max(0, min(1, fraction))
        let path = CGMutablePath()
        // Limb semicircle: right side when waxing, left side when waning.
        path.move(to: CGPoint(x: center.x, y: center.y + radius))
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .pi / 2,
            endAngle: -.pi / 2,
            clockwise: waxing
        )
        // Terminator: a half-ellipse scaled horizontally by |1 − 2·fraction|.
        let scaleX = abs(1 - 2 * fraction)
        let terminatorClockwise = waxing ? (fraction >= 0.5) : (fraction < 0.5)
        let transform = CGAffineTransform(translationX: center.x, y: center.y)
            .scaledBy(x: max(scaleX, 0.0001), y: 1)
        path.addArc(
            center: .zero,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: .pi / 2,
            clockwise: terminatorClockwise,
            transform: transform
        )
        path.closeSubpath()
        return path
    }

    /// Draws the moon glyph (circle outline + lit region) into the current
    /// context using `color`. `rect` is the full glyph bounds.
    static func drawGlyph(fraction: Double, waxing: Bool, in rect: CGRect, color: NSColor) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let inset = rect.insetBy(dx: 1, dy: 1)
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(1.1)
        context.strokeEllipse(in: inset)
        context.addPath(illuminatedPath(fraction: fraction, waxing: waxing, in: inset))
        context.setFillColor(color.cgColor)
        context.fillPath()
    }

    /// A template menu-bar icon: circle outline plus inked lit region.
    static func statusImage(fraction: Double, waxing: Bool, pointSize: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: pointSize, height: pointSize), flipped: false) { rect in
            drawGlyph(fraction: fraction, waxing: waxing, in: rect, color: .black)
            return true
        }
        image.isTemplate = true
        return image
    }
}

/// Small view that renders a single moon phase using `MoonArt`.
final class MoonDiscView: NSView {
    var fraction: Double = 0.5 { didSet { needsDisplay = true } }
    var waxing: Bool = true { didSet { needsDisplay = true } }
    var outlineColor: NSColor = Palette.line2 { didSet { needsDisplay = true } }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) { nil }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let rect = bounds.insetBy(dx: 0.7, dy: 0.7)
        // Unlit disc (dark) first, then the illuminated region painted bright —
        // so a full moon reads as a bright disc, a new moon as a dark one.
        context.setFillColor(Palette.moonShadow.cgColor)
        context.fillEllipse(in: rect)
        context.addPath(MoonArt.illuminatedPath(fraction: fraction, waxing: waxing, in: rect))
        context.setFillColor(Palette.moonLit.cgColor)
        context.fillPath()
        context.setStrokeColor(outlineColor.cgColor)
        context.setLineWidth(1.1)
        context.strokeEllipse(in: rect)
    }
}
