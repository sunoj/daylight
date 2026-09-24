// Guards the moon path's screens against rendering blank.
// Exports: MoonScreenLayoutTests
// Deps: XCTest, AppKit, DaylightMenuBarKit

import AppKit
import XCTest
@testable import DaylightMenuBarKit

/// `PopoverViewController.sizeToFit` sizes each screen from its `fittingSize`
/// and clamps to `max(height, 1)`, so a panel that fails to lay out collapses
/// to a 1pt-tall popover — a blank page rather than a crash. These assert the
/// two screens on the moon path actually have height.
final class MoonScreenLayoutTests: XCTestCase {
    @MainActor func testLocationPromptPanelLaysOut() {
        // Regression: the pills pinned their width to the panel before being
        // added to it. Activating a constraint across two views with no common
        // ancestor throws, and the whole prompt came up blank.
        let panel = LocationPromptPanel(onAllow: {}, onSkip: {})
        XCTAssertGreaterThan(fittingHeight(of: panel), 1)
    }

    @MainActor func testMoon3DPanelLaysOut() {
        let panel = Moon3DPanel(
            displayDate: LocalDate(year: 2026, month: 7, day: 23),
            requestLocation: false,
            onClose: {}
        )
        XCTAssertGreaterThan(fittingHeight(of: panel), 1)
    }

    /// `radius: 999` is the pill idiom. Passed to CoreAnimation unclamped on a
    /// wide box it is undefined and drew nothing at all — the location prompt's
    /// buttons vanished. LayerColorView must clamp it to half the shorter side.
    @MainActor func testPillRadiusIsClampedToHalfTheShorterSide() {
        let box = UI.roundedBox(fill: .black, radius: 999)
        box.frame = NSRect(x: 0, y: 0, width: 344, height: 44)
        box.layoutSubtreeIfNeeded()
        box.displayIfNeeded()
        XCTAssertEqual(box.layer?.cornerRadius, 22)
    }

    @MainActor func testSmallRadiusIsLeftAlone() {
        let box = UI.roundedBox(fill: .black, radius: 8)
        box.frame = NSRect(x: 0, y: 0, width: 344, height: 44)
        box.layoutSubtreeIfNeeded()
        box.displayIfNeeded()
        XCTAssertEqual(box.layer?.cornerRadius, 8)
    }

    @MainActor private func fittingHeight(of panel: NSView) -> CGFloat {
        panel.widthAnchor.constraint(equalToConstant: Metrics.popoverWidth).isActive = true
        panel.layoutSubtreeIfNeeded()
        return panel.fittingSize.height
    }
}
