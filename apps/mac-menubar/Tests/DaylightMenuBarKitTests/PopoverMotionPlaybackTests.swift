// Runtime coverage for transition playback and toast visibility.
// Exports: PopoverMotionPlaybackTests
// Deps: XCTest, AppKit, DaylightMenuBarKit

import AppKit
import XCTest
@testable import DaylightMenuBarKit

@MainActor
final class PopoverMotionPlaybackTests: XCTestCase {
    override func tearDown() {
        Motion.reduceMotionOverride = nil
        super.tearDown()
    }

    /// The toast fades in through `alphaValue`, which `makeToast` leaves at 0.
    /// Animating layer opacity instead left the model value behind and the box
    /// vanished the instant the animation was removed.
    @MainActor
    func testToastBecomesVisibleAfterShowing() {
        for reduced in [true, false] {
            Motion.reduceMotionOverride = reduced
            let controller = makeController()
            _ = controller.view
            controller.showToast("saved")

            guard let box = toastBox(in: controller.view) else {
                return XCTFail("toast not found (reduceMotion: \(reduced))")
            }
            XCTAssertEqual(box.alphaValue, 1, accuracy: 0.001, "reduceMotion: \(reduced)")
        }
    }

    @MainActor
    func testReducedMotionRendersWithoutASnapshotOverlay() {
        Motion.reduceMotionOverride = true
        let controller = makeController()
        _ = controller.view
        controller.show(.settings)

        XCTAssertNil(overlay(in: controller.view))
        XCTAssertEqual(controller.screen, .settings)
    }

    @MainActor
    func testTransitionRemovesItsOverlayAndRestoresTheRootStack() {
        Motion.reduceMotionOverride = false
        let controller = makeController()
        _ = controller.view
        controller.show(.settings)
        XCTAssertNotNil(overlay(in: controller.view), "expected a snapshot overlay during the push")

        let settled = expectation(description: "transition settles")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { settled.fulfill() }
        wait(for: [settled], timeout: 2)

        XCTAssertNil(overlay(in: controller.view), "snapshot overlay outlived the transition")
        XCTAssertEqual(controller.rootStack.layer?.opacity ?? 1, 1, accuracy: 0.001)
        XCTAssertTrue(CATransform3DIsIdentity(controller.rootStack.layer?.transform ?? CATransform3DIdentity))
    }

    /// The fade-out is an animation, which drives the presentation layer only.
    /// With the model left at 1 the old screen snapped back to fully opaque for
    /// a frame when CoreAnimation removed it — a flash of the previous month on
    /// every step through the calendar.
    @MainActor
    func testOutgoingSnapshotSettlesTransparent() {
        Motion.reduceMotionOverride = false
        for (label, act) in transitions() {
            let controller = makeController()
            _ = controller.view
            act(controller)

            guard let overlay = overlay(in: controller.view), let layer = overlay.layer else {
                return XCTFail("no snapshot overlay for \(label)")
            }
            XCTAssertEqual(layer.opacity, 0, accuracy: 0.001, "\(label) leaves the old screen opaque")
            XCTAssertNotNil(layer.animation(forKey: "opacity"), "\(label) is not animating")
        }
    }

    @MainActor
    private func transitions() -> [(String, (PopoverViewController) -> Void)] {
        [
            ("next month", { $0.nextPeriod() }),
            ("previous month", { $0.previousPeriod() }),
            ("zoom out", { $0.zoomOut() }),
            ("push to settings", { $0.show(.settings) })
        ]
    }

    /// Back-to-back renders must not strand the first transition's snapshot on
    /// top of the live view tree.
    @MainActor
    func testSuccessiveTransitionsKeepAtMostOneOverlay() {
        Motion.reduceMotionOverride = false
        let controller = makeController()
        _ = controller.view
        controller.show(.settings)
        controller.show(.holidays)
        controller.show(.settings)

        XCTAssertEqual(overlays(in: controller.view).count, 1)
    }

    @MainActor
    private func makeController() -> PopoverViewController {
        let defaults = UserDefaults(suiteName: "daylight.motion.\(UUID().uuidString)")!
        let store = DaylightStore(defaults: defaults)
        var settings = store.settings()
        settings.uiMode = "sol"
        store.saveSettings(settings)
        return PopoverViewController(store: store, calendarModel: CalendarModel(), onDataChanged: {})
    }

    @MainActor
    private func overlay(in view: NSView) -> NSImageView? {
        overlays(in: view).first
    }

    @MainActor
    private func overlays(in view: NSView) -> [NSImageView] {
        view.subviews.compactMap { $0 as? NSImageView }
    }

    /// The toast is the only view pinned to the root that carries the message
    /// label, so find it by walking up from the label.
    @MainActor
    private func toastBox(in view: NSView) -> NSView? {
        guard let label = firstLabel(withValue: "saved", in: view) else { return nil }
        return label.superview
    }

    @MainActor
    private func firstLabel(withValue value: String, in view: NSView) -> NSTextField? {
        if let field = view as? NSTextField, field.stringValue == value { return field }
        for subview in view.subviews {
            if let match = firstLabel(withValue: value, in: subview) { return match }
        }
        return nil
    }
}
