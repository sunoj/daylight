// Composes ordered status segments into one template menu bar image.
// Exports: StatusBarRenderer
// Deps: AppKit, StatusSegment, MoonArt

import AppKit

enum StatusBarRenderer {
    private static let height: CGFloat = 16
    private static let iconSize: CGFloat = 15
    private static let boxSize: CGFloat = 15
    private static let spacing: CGFloat = 5
    /// Renders `segments` left-to-right. Returns nil when there is nothing to draw.
    static func image(for segments: [StatusSegment]) -> NSImage? {
        guard !segments.isEmpty else { return nil }
        let widths = segments.map(width(of:))
        let total = widths.reduce(0, +) + spacing * CGFloat(segments.count - 1)
        guard total > 0 else { return nil }
        let image = NSImage(size: NSSize(width: total, height: height), flipped: false) { _ in
            var x: CGFloat = 0
            for (index, segment) in segments.enumerated() {
                draw(segment, at: x)
                x += widths[index] + spacing
            }
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func width(of segment: StatusSegment) -> CGFloat {
        switch segment {
        case .moon: return iconSize
        case .dateBox: return boxSize
        case let .text(value): return textSize(value).width
        }
    }

    private static func draw(_ segment: StatusSegment, at x: CGFloat) {
        switch segment {
        case let .moon(fraction, waxing):
            MoonArt.drawGlyph(fraction: fraction, waxing: waxing, in: CGRect(x: x, y: 0, width: iconSize, height: height), color: Palette.shadow)
        case let .dateBox(day):
            drawDateBox(day, at: x)
        case let .text(value):
            drawText(value, at: x)
        }
    }

    private static func drawText(_ value: String, at x: CGFloat) {
        let attributes = textAttributes()
        let size = value.size(withAttributes: attributes)
        value.draw(at: CGPoint(x: x, y: (height - size.height) / 2), withAttributes: attributes)
    }

    private static func drawDateBox(_ day: String, at x: CGFloat) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let rect = CGRect(x: x + 0.6, y: 0.6, width: boxSize - 1.2, height: height - 1.2)
        let box = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)
        context.setStrokeColor(Palette.shadow.cgColor)
        box.lineWidth = 1.2
        box.stroke()
        let attributes = textAttributes(size: boxSize <= 15 ? 9 : 10, weight: .semibold)
        let size = day.size(withAttributes: attributes)
        day.draw(
            at: CGPoint(x: x + (boxSize - size.width) / 2, y: (height - size.height) / 2),
            withAttributes: attributes
        )
    }

    private static func textSize(_ value: String) -> NSSize {
        value.size(withAttributes: textAttributes())
    }

    private static func textAttributes(size: CGFloat = 13, weight: NSFont.Weight = .regular) -> [NSAttributedString.Key: Any] {
        [
            // System font, not the design system's IBM Plex: this draws into the
            // menu bar, which is the one surface that should match the OS chrome
            // around it rather than the popover's typography.
            .font: NSFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: Palette.shadow
        ]
    }
}
