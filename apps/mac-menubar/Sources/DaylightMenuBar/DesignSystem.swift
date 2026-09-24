// Design tokens for the 朴素/plain menu bar UI (colors, fonts, metrics).
// Exports: Palette, Typography, Metrics
// Deps: AppKit

import AppKit
import CoreText

/// Appearance-aware colors mapped from the design system's CSS variables.
/// Each token resolves per the current NSAppearance so light/dark switch
/// automatically, matching `.dark` overrides in colors_and_type.css.
enum Palette {
    static let ink = dynamic(light: 0x1B1B1A, dark: 0xECEBE7)
    static let ink2 = dynamic(light: 0x5C5B57, dark: 0xA7A6A0)
    static let ink3 = dynamic(light: 0x8A8984, dark: 0x7A7974)
    static let ink4 = dynamic(light: 0xB3B2AC, dark: 0x54534F)

    static let paper = dynamic(light: 0xF6F5F3, dark: 0x161614)
    static let surface = dynamic(light: 0xFFFFFF, dark: 0x1E1E1C)
    static let surface2 = dynamic(light: 0xEFEEEB, dark: 0x262624)
    static let surface3 = dynamic(light: 0xE7E5E1, dark: 0x2F2F2C)

    /// Persistent date selection, distinct from the neutral hover surface.
    static let dateSelection = dynamic(light: 0xE1E8DC, dark: 0x354133)
    static let dateSelectionBorder = dynamic(light: 0xA8B79F, dark: 0x71846A)

    static let line = dynamic(light: 0xE4E2DD, dark: 0x2C2C29)
    static let line2 = dynamic(light: 0xD5D3CD, dark: 0x3A3A36)

    /// Accent is the ink; text/icon on a filled accent is the paper.
    static let accent = ink
    static let accentInk = dynamic(light: 0xFFFFFF, dark: 0x161614)

    static let pos = dynamic(light: 0x5E7257, dark: 0x8FA487)
    static let neg = dynamic(light: 0x97574B, dark: 0xC08579)
    /// Quiet muted-red used to mark public holidays in the grid.
    static let rust = dynamic(light: 0xA8544A, dark: 0xD08A7D)
    static let stone = dynamic(light: 0x4A5A6B, dark: 0x8FA0B3)
    static let olive = dynamic(light: 0x6A6E52, dark: 0xA3A88A)
    static let amber = dynamic(light: 0x9A7B43, dark: 0xC4A66B)
    static let green = dynamic(light: 0x5E7257, dark: 0x8FA487)
    static let holiday = rust

    /// Fixed moon colors (identical in light/dark): dark unlit disc, pale lit face.
    static let moonLit = rgb(0xF4F2EC)
    static let moonShadow = rgb(0x33322E)

    /// A moon behind date text uses a compressed tonal range: both halves
    /// remain legible with todayMoonInk, including at the terminator boundary.
    static let todayMoonLit = dynamic(light: 0xF3DFA6, dark: 0xF4F2EC)
    static let todayMoonShadow = dynamic(light: 0xC0AD82, dark: 0xACB6A4)
    static let todayMoonInk = dynamic(light: 0x3B3221, dark: 0x161614)

    /// Popover shell backgrounds. Light stays opaque; dark is translucent so
    /// NSPopover's vibrancy material shows through (frosted glass).
    static let popoverBackground = dynamicAlpha(light: 0xFFFFFF, dark: 0x1E1E1C, darkAlpha: 0.70)
    /// Luna agenda panel — slightly lighter tint than the footer; dark alpha keeps
    /// eventInk readable while preserving the two-tone split over the blurred root.
    static let popoverEventPanel = dynamicAlpha(light: 0x282826, dark: 0x282826, darkAlpha: 0.82)
    static let popoverEventFooter = dynamicAlpha(light: 0x1E1E1C, dark: 0x1E1E1C, darkAlpha: 0.78)

    /// The agenda surface stays dark in both appearances for the deliberate two-tone split.
    static let eventPanel = rgb(0x282826)
    static let eventFooter = rgb(0x1E1E1C)
    static let eventLine = rgb(0x3A3A36)
    static let eventInk = rgb(0xECEBE7)
    static let eventInk2 = rgb(0xA7A6A0)
    static let eventInk3 = rgb(0x76756F)
    static let shadow = rgb(0x000000)

    static func dynamic(light: Int, dark: Int) -> NSColor {
        NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return rgb(isDark ? dark : light)
        }
    }

    static func dynamicAlpha(light: Int, dark: Int, lightAlpha: CGFloat = 1, darkAlpha: CGFloat = 1) -> NSColor {
        NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            let hex = isDark ? dark : light
            let alpha = isDark ? darkAlpha : lightAlpha
            return rgb(hex).withAlphaComponent(alpha)
        }
    }

    static func rgb(_ hex: Int) -> NSColor {
        NSColor(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }

    static func holidayColor(_ id: String) -> NSColor {
        switch id {
        case "stone": return stone
        case "olive": return olive
        case "amber": return amber
        case "green": return green
        default: return rust
        }
    }
}

/// Font roles using the bundled IBM Plex family (design typeface), with
/// system fallbacks. Sans is a variable font weighted via descriptor traits;
/// Mono uses the Regular/Medium statics.
enum Typography {
    // 'wght' variable-font axis identifier.
    private static let weightAxis = 0x77676874

    static func sans(_ size: CGFloat, _ weight: NSFont.Weight = .regular) -> NSFont {
        Fonts.ensureRegistered
        guard let base = NSFont(name: "IBMPlexSans-Regular", size: size) else {
            return .systemFont(ofSize: size, weight: weight)
        }
        let value: CGFloat
        switch weight {
        case .semibold: value = 600
        case .medium: value = 500
        case .bold: value = 700
        default: return base
        }
        let descriptor = base.fontDescriptor.addingAttributes([.variation: [weightAxis: value]])
        return NSFont(descriptor: descriptor, size: size) ?? base
    }

    static func mono(_ size: CGFloat, _ weight: NSFont.Weight = .regular) -> NSFont {
        Fonts.ensureRegistered
        let name = weight == .regular ? "IBMPlexMono-Regular" : "IBMPlexMono-Medium"
        return NSFont(name: name, size: size) ?? .monospacedSystemFont(ofSize: size, weight: weight)
    }
}

/// Registers the bundled IBM Plex TTFs with the font manager exactly once.
enum Fonts {
    static let ensureRegistered: Void = {
        for name in ["IBMPlexSans-VF", "IBMPlexMono-Regular", "IBMPlexMono-Medium"] {
            guard let url = Bundle.module.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()
}

/// Shared geometry constants for the compact popover.
enum Metrics {
    static let popoverWidth: CGFloat = 412
    /// Luna gets its own narrower width so the compact grid is not padded like Sol.
    static let lunaPopoverWidth: CGFloat = 300
    static let cellHeight: CGFloat = 44
    /// Row height when day cells carry no subtitle (农历 off and no holiday
    /// names), so the grid stays compact and the week number lines up with
    /// the date number.
    static let compactCellHeight: CGFloat = 32
    static let cellRadius: CGFloat = 9
    static let cardRadius: CGFloat = 12
    static let tileRadius: CGFloat = 8
    static let gridGap: CGFloat = 2
    static let contentInset: CGFloat = 14
    static let weekColumnWidth: CGFloat = 26
    /// Sol's selected-day agenda hugs its document height until this cap, then scrolls.
    static let solAgendaMaxHeight: CGFloat = 180
    /// Luna-grid day cell: one number plus a row of event dots.
    static let lunaCellHeight: CGFloat = 36
    /// Luna-grid day cell with an optional lunar subtitle line.
    static let lunaCellHeightTall: CGFloat = 46
    static let lunaSubtitleFontSize: CGFloat = 8.5
    /// Luna day-cell layout: number line, label stack, dot row, and selection circle.
    static let lunaNumberLineHeight: CGFloat = 15
    static let lunaSubtitleLineHeight: CGFloat = 10
    static let lunaLabelStackSpacing: CGFloat = 1
    static let lunaDotSize: CGFloat = 4
    static let lunaDotSpacing: CGFloat = 3
    static let lunaDotRowGap: CGFloat = 2
    /// Padding inside the today/selected circle around the number, subtitle, and dots.
    static let lunaCirclePadding: CGFloat = 1
    /// Minimum gap between the circle edge and the cell edge (gridGap keeps adjacent circles apart).
    static let lunaCircleEdgeInset: CGFloat = 2

    /// One diameter per grid variant, not per cell. Deriving it from each cell's
    /// own content made the circle change size from day to day — a today with
    /// events got a bigger disc than a selected day without — and sizing it from
    /// content HEIGHT alone made it narrower than the two-digit number, which
    /// then overflowed its own circle.
    static func lunaCircleDiameter(showsSubtitle: Bool) -> CGFloat {
        showsSubtitle ? lunaCellHeightTall - 2 * lunaCircleEdgeInset : lunaCellHeight - 2 * lunaCircleEdgeInset
    }

    /// Dots sit this far above the circle's bottom edge. Far enough in that the
    /// row is inside the curve rather than riding on it.
    static let lunaDotInset: CGFloat = 5

    /// Dots shown per Luna cell. Capped by the circle's width at the dot row.
    static let lunaMaxDots: Int = 3
}
