// Regression coverage for coalesced re-entrant rendering.
// Exports: RenderCoalescerTests
// Deps: XCTest, DaylightMenuBarKit

import XCTest
@testable import DaylightMenuBarKit

final class RenderCoalescerTests: XCTestCase {
    func testReentrantRequestsProduceOneFollowUpRender() {
        var renderCount = 0
        var coalescer: RenderCoalescer!
        coalescer = RenderCoalescer {
            renderCount += 1
            if renderCount == 1 {
                coalescer.request()
                coalescer.request()
            }
        }

        coalescer.request()

        XCTAssertEqual(renderCount, 2)
    }
}
