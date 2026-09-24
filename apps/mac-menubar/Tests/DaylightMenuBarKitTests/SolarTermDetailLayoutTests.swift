// Selected-date solar-term placement and ordinary-day fallback in both Mac layouts.
import AppKit
import XCTest
@testable import DaylightMenuBarKit

@MainActor
final class SolarTermDetailLayoutTests: XCTestCase {
    func testSelectedDayShowsCompactIconBesideMoonInBothLayouts() throws {
        for mode in ["luna", "sol"] {
            let screen = makeScreen(mode: mode, day: 4)
            let icon = try XCTUnwrap(descendant(SolarTermIconView.self, in: screen))
            XCTAssertEqual(icon.term, "立春")
            XCTAssertEqual(icon.variant, .small)
            XCTAssertEqual(icon.toolTip, "立春")
            XCTAssertEqual(icon.frame.width, mode == "luna" ? 20 : 24, accuracy: 0.1)
            let moon = try XCTUnwrap(descendant(MoonDiscView.self, in: screen))
            let iconRect = icon.convert(icon.bounds, to: screen)
            let moonRect = moon.convert(moon.bounds, to: screen)
            XCTAssertFalse(iconRect.intersects(moonRect))
            XCTAssertEqual(iconRect.midY, moonRect.midY, accuracy: 1)
            XCTAssertTrue(screen.bounds.contains(iconRect))
            if mode == "luna" {
                XCTAssertEqual(icon.tintColor, Palette.eventInk2)
                XCTAssertFalse(icon.superview is RowButton)
                let readout = try XCTUnwrap(descendant(CompactMoonReadout.self, in: screen))
                let name = try XCTUnwrap(descendant(NSTextField.self, in: readout))
                XCTAssertGreaterThanOrEqual(name.frame.width, (name.stringValue as NSString).size(withAttributes: [.font: name.font!]).width + 4)
            }
            try exportPreview(screen, name: mode)
        }
    }

    func testOrdinaryDayOmitsTermAndPreservesMoon() {
        for mode in ["luna", "sol"] {
            let screen = makeScreen(mode: mode, day: 5)
            XCTAssertNil(descendant(SolarTermIconView.self, in: screen))
            XCTAssertNotNil(descendant(MoonDiscView.self, in: screen))
        }
    }

    func testLunarSettingHidesTermAndPreservesMoonInBothLayouts() {
        for mode in ["luna", "sol"] {
            let screen = makeScreen(mode: mode, day: 4, showLunarDate: false)
            XCTAssertNil(descendant(SolarTermIconView.self, in: screen))
            XCTAssertNotNil(descendant(MoonDiscView.self, in: screen))
        }
    }

    private func makeScreen(mode: String, day: Int, showLunarDate: Bool = true) -> NSView {
        let suite = "daylight.solar-detail.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = DaylightStore(defaults: defaults)
        var settings = store.settings()
        settings.uiMode = mode
        // Opposite values ensure each layout follows its own lunar preference.
        settings.lunaShowLunarDate = mode == "luna" ? showLunarDate : !showLunarDate
        settings.showLunarDate = mode == "sol" ? showLunarDate : !showLunarDate
        settings.systemCalendarEnabled = false
        settings.language = "zh"
        store.saveSettings(settings)
        let controller = PopoverViewController(store: store, calendarModel: CalendarModel(), onDataChanged: {})
        controller.selectedDate = LocalDate(year: 2024, month: 2, day: day)
        controller.visibleMonth = LocalDate(year: 2024, month: 2, day: 1)
        let screen = mode == "luna" ? controller.lunaScreen() : controller.calendarScreen(eventsByDay: [:])
        let width = mode == "luna" ? Metrics.lunaPopoverWidth : Metrics.popoverWidth
        screen.translatesAutoresizingMaskIntoConstraints = false
        screen.widthAnchor.constraint(equalToConstant: width).isActive = true
        screen.frame = NSRect(origin: .zero, size: screen.fittingSize)
        screen.layoutSubtreeIfNeeded()
        return screen
    }

    private func descendant<T: NSView>(_ type: T.Type, in view: NSView) -> T? {
        if let match = view as? T { return match }
        return view.subviews.lazy.compactMap { self.descendant(type, in: $0) }.first
    }

    private func exportPreview(_ view: NSView, name: String) throws {
        guard let directory = ProcessInfo.processInfo.environment["DAYLIGHT_ICON_PREVIEW_DIR"] else { return }
        for (label, appearance) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
            view.appearance = NSAppearance(named: appearance)
            view.layoutSubtreeIfNeeded()
            let rep = try XCTUnwrap(view.bitmapImageRepForCachingDisplay(in: view.bounds))
            view.cacheDisplay(in: view.bounds, to: rep)
            let data = try XCTUnwrap(rep.representation(using: .png, properties: [:]))
            try data.write(to: URL(fileURLWithPath: directory).appendingPathComponent("\(name)-\(label).png"))
        }
    }
}
