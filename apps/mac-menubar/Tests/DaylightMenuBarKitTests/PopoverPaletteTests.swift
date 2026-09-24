// Verifies popover frosted-glass palette tokens resolve correctly per appearance.
// Exports: PopoverPaletteTests
// Deps: AppKit, DesignSystem, XCTest

import AppKit
import XCTest
@testable import DaylightMenuBarKit

final class PopoverPaletteTests: XCTestCase {
    private func resolved(_ color: NSColor, appearance: NSAppearance) -> NSColor {
        var result = color
        appearance.performAsCurrentDrawingAppearance {
            result = color.usingColorSpace(.deviceRGB) ?? color
        }
        return result
    }

    func testPopoverBackgroundTranslucentInDarkOpaqueInLight() {
        let light = resolved(Palette.popoverBackground, appearance: NSAppearance(named: .aqua)!)
        let dark = resolved(Palette.popoverBackground, appearance: NSAppearance(named: .darkAqua)!)
        XCTAssertEqual(light.alphaComponent, 1, accuracy: 0.001)
        XCTAssertEqual(dark.alphaComponent, 0.70, accuracy: 0.001)
    }

    func testPopoverEventPanelTranslucentOnlyInDark() {
        let light = resolved(Palette.popoverEventPanel, appearance: NSAppearance(named: .aqua)!)
        let dark = resolved(Palette.popoverEventPanel, appearance: NSAppearance(named: .darkAqua)!)
        XCTAssertEqual(light.alphaComponent, 1, accuracy: 0.001)
        XCTAssertEqual(dark.alphaComponent, 0.82, accuracy: 0.001)
    }

    func testPopoverEventFooterTranslucentOnlyInDark() {
        let light = resolved(Palette.popoverEventFooter, appearance: NSAppearance(named: .aqua)!)
        let dark = resolved(Palette.popoverEventFooter, appearance: NSAppearance(named: .darkAqua)!)
        XCTAssertEqual(light.alphaComponent, 1, accuracy: 0.001)
        XCTAssertEqual(dark.alphaComponent, 0.78, accuracy: 0.001)
    }

    func testEventPanelFooterStayOpaqueInLight() {
        let lightPanel = resolved(Palette.popoverEventPanel, appearance: NSAppearance(named: .aqua)!)
        let lightFooter = resolved(Palette.popoverEventFooter, appearance: NSAppearance(named: .aqua)!)
        XCTAssertEqual(lightPanel.alphaComponent, 1, accuracy: 0.001)
        XCTAssertEqual(lightFooter.alphaComponent, 1, accuracy: 0.001)
    }
}
