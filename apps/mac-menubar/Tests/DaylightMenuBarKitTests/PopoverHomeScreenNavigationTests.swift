// Regression coverage for popover return-to-home navigation.
// Exports: PopoverHomeScreenNavigationTests
// Deps: XCTest, AppKit, DaylightMenuBarKit

import AppKit
import XCTest
@testable import DaylightMenuBarKit

@MainActor
final class PopoverHomeScreenNavigationTests: XCTestCase {
    @MainActor
    func testClosingMoonReturnsToModeHomeScreen() {
        for mode in ["luna", "sol"] {
            let defaults = UserDefaults(suiteName: "daylight.home-screen.\(mode).\(UUID().uuidString)")!
            let store = DaylightStore(defaults: defaults)
            var settings = store.settings()
            settings.uiMode = mode
            store.saveSettings(settings)

            let controller = PopoverViewController(store: store, calendarModel: CalendarModel(), onDataChanged: {})
            _ = controller.view

            let expectedHome: PopoverScreen = mode == "luna" ? .luna : .calendar
            XCTAssertEqual(controller.homeScreen, expectedHome)
            XCTAssertEqual(controller.screen, expectedHome)

            controller.moonWantsLocation = false
            controller.show(.moon)
            XCTAssertEqual(controller.screen, .moon)

            tapHeaderClose(in: firstSubview(of: Moon3DPanel.self, in: controller.view))
            XCTAssertEqual(controller.screen, expectedHome)

        }
    }

    @MainActor
    private func tapHeaderClose(in panel: NSStackView?) {
        guard let panel, let close = headerCloseButton(in: panel) else {
            return XCTFail("header close control not found")
        }
        close.mouseDown(with: NSEvent())
    }

    @MainActor
    private func headerCloseButton(in panel: NSStackView) -> RowButton? {
        guard let header = panel.arrangedSubviews.first as? NSStackView else { return nil }
        return header.arrangedSubviews.last as? RowButton
    }

    @MainActor
    private func firstSubview<T: NSView>(of type: T.Type, in view: NSView) -> T? {
        if let match = view as? T { return match }
        for subview in view.subviews {
            if let match = firstSubview(of: type, in: subview) { return match }
        }
        return nil
    }
}
