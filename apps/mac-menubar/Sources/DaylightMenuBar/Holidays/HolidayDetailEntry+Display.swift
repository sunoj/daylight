// Display strings for holiday detail rows in Luna and Sol panels.
// Exports: HolidayDetailEntry display helpers
// Deps: Foundation, AppKit, DesignSystem

import AppKit
import Foundation

extension HolidayDetailEntry {
    var displayTitle: String {
        let name = day.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? typeLabel : L(name)
    }

    var displaySubtitle: String {
        let source = L(sourceName)
        guard day.type != "holiday" else { return source }
        return "\(source) · \(typeLabel)"
    }

    var typeLabel: String {
        switch day.type {
        case "workday": return L("调休上班")
        case "observance": return L("纪念日")
        default: return L("节假日")
        }
    }

    var badgeColor: NSColor {
        colorId.map(Palette.holidayColor) ?? Palette.rust
    }
}
