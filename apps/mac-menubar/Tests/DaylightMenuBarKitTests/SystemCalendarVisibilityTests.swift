// Unit tests for per-calendar visibility helpers.
// Exports: SystemCalendarVisibilityTests
// Deps: XCTest, DaylightMenuBarKit

import XCTest
@testable import DaylightMenuBarKit

final class SystemCalendarVisibilityTests: XCTestCase {
    func testUnknownCalendarIdCountsAsVisible() {
        XCTAssertTrue(SystemCalendarVisibility.isVisible(calendarId: "new-calendar", hiddenIds: ["work", "home"]))
    }

    func testHiddenCalendarIdIsExcludedFromVisibleCount() {
        let all = ["work", "home", "family"]
        XCTAssertEqual(SystemCalendarVisibility.visibleCount(allIds: all, hiddenIds: ["home"]), 2)
    }

    func testToggleVisibilityAddsAndRemovesHiddenId() {
        XCTAssertEqual(
            SystemCalendarVisibility.toggleVisibility(calendarId: "work", hiddenIds: []),
            ["work"]
        )
        XCTAssertEqual(
            SystemCalendarVisibility.toggleVisibility(calendarId: "work", hiddenIds: ["work", "home"]),
            ["home"]
        )
    }
}
