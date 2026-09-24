// EventKit calendar metadata exposed to settings UI.
// Exports: SystemCalendarInfo
// Deps: AppKit, Palette

import AppKit
import Foundation

struct SystemCalendarInfo: Equatable, Hashable {
    let id: String
    let title: String
    let colorHex: String
    let sourceTitle: String

    var color: NSColor {
        guard colorHex.count == 6, let value = Int(colorHex, radix: 16) else { return Palette.ink2 }
        return Palette.rgb(value)
    }
}
