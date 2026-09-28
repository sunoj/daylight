// Compact workday marker, independent of lunar-date visibility.
import AppKit

enum CalendarWorkdayBadge {
    /// Margins from the cell's top and trailing edges.
    static let topInset: CGFloat = 1
    static let trailingInset: CGFloat = 2

    /// The badge label alone, for cells that position it by frame.
    static func make(color: NSColor) -> NSTextField {
        let badge = UI.label(Loc.language == .zh || Loc.language == .zhHant ? "班" : "W", font: Typography.sans(8, .semibold), color: color, align: .right)
        badge.toolTip = L("调休上班")
        badge.setAccessibilityLabel(L("调休上班"))
        return badge
    }

    /// A frame with room to spare, anchored where the tight one was: the glyph
    /// is right-aligned, so it lands in the same spot, but a width measured
    /// before the popover had a window no longer clips it once drawn there.
    static func frame(for badge: NSTextField, in bounds: NSRect, flipped: Bool) -> NSRect {
        let size = badge.intrinsicContentSize
        let width = size.width + 8, height = size.height + 4
        let top = flipped ? bounds.minY + topInset : bounds.maxY - topInset - height
        return NSRect(x: bounds.maxX - trailingInset - width, y: top, width: width, height: height)
    }
}
