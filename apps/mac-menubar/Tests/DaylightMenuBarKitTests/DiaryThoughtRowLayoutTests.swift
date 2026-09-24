// Layout guard for the diary thought row.
// Exports: DiaryThoughtRowLayoutTests
// Deps: XCTest, AppKit, DaylightMenuBarKit

import AppKit
import XCTest
@testable import DaylightMenuBarKit

final class DiaryThoughtRowLayoutTests: XCTestCase {
    /// The delete control belongs at the row's trailing edge and the text must
    /// fill what is left. Three nested mistakes each collapsed this instead —
    /// the scroll's document view was never pinned to its clip view, so rows
    /// shrank to intrinsic width; the rows were added to a .leading stack
    /// without a width pin; and tuning stack hugging crushed the text to 4pt.
    /// Measure it rather than eyeballing a screenshot.
    func testRowFillsItsWidthAndPinsDeleteToTheTrailingEdge() {
        let width: CGFloat = 380
        let view = DiaryThoughtTimelineView()
        view.render(thoughts: [
            DiaryThought(id: "a", date: "2026-08-20", content: "发布新应用",
                         createdAt: "2026-08-20T15:45:00.000Z", updatedAt: "2026-08-20T15:45:00.000Z")
        ])
        view.frame = NSRect(x: 0, y: 0, width: width, height: 120)
        view.layoutSubtreeIfNeeded()

        var text: NSTextField?
        var remove: DiaryThoughtDeleteButton?
        func walk(_ v: NSView) {
            if let field = v as? NSTextField, field.stringValue == "发布新应用" { text = field }
            if let button = v as? DiaryThoughtDeleteButton { remove = button }
            v.subviews.forEach(walk)
        }
        walk(view)

        guard let text, let remove else { return XCTFail("row subviews not found") }
        let textFrame = text.convert(text.bounds, to: view)
        let removeFrame = remove.convert(remove.bounds, to: view)

        XCTAssertGreaterThan(textFrame.width, width / 2,
                             "text collapsed to \(textFrame.width)pt of \(width)")
        XCTAssertEqual(removeFrame.maxX, width, accuracy: 1,
                       "delete control is at \(removeFrame.maxX), not the row's trailing edge")
        XCTAssertLessThanOrEqual(textFrame.maxX, removeFrame.minX + 1, "text overlaps the delete control")
    }
}
