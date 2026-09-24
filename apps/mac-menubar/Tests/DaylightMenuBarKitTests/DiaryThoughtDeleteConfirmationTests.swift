// Two-step confirmation coverage for diary thought deletion.
// Exports: DiaryThoughtDeleteConfirmationTests
// Deps: XCTest, AppKit, DaylightMenuBarKit

import AppKit
import XCTest
@testable import DaylightMenuBarKit

@MainActor
final class DiaryThoughtDeleteConfirmationTests: XCTestCase {
    func testOneClickArmsWithoutDeleting() throws {
        let defaults = UserDefaults(suiteName: "daylight.diary-delete-confirm.\(UUID().uuidString)")!
        let store = DaylightStore(defaults: defaults)
        let date = LocalDate(year: 2026, month: 8, day: 20)
        store.addThought(for: date, content: "保留这条")
        let thought = try XCTUnwrap(store.thoughts(for: date).first)
        let timeline = DiaryThoughtTimelineView()
        var deletedID: String?
        timeline.onDelete = { deletedID = $0; store.deleteThought(id: $0) }
        timeline.render(thoughts: [thought])

        let button = try deleteButton(for: thought.id, in: timeline)
        button.mouseDown(with: NSEvent())

        XCTAssertTrue(button.isArmed)
        XCTAssertNil(deletedID)
        XCTAssertEqual(store.thoughts(for: date).map(\.id), [thought.id])
    }

    func testSecondClickOnSameRowDeletes() throws {
        let defaults = UserDefaults(suiteName: "daylight.diary-delete-confirm.\(UUID().uuidString)")!
        let store = DaylightStore(defaults: defaults)
        let date = LocalDate(year: 2026, month: 8, day: 20)
        store.addThought(for: date, content: "删除这条")
        let thought = try XCTUnwrap(store.thoughts(for: date).first)
        let timeline = DiaryThoughtTimelineView()
        var deletedID: String?
        timeline.onDelete = { deletedID = $0; store.deleteThought(id: $0) }
        timeline.render(thoughts: [thought])

        let button = try deleteButton(for: thought.id, in: timeline)
        button.mouseDown(with: NSEvent())
        button.mouseDown(with: NSEvent())

        XCTAssertEqual(deletedID, thought.id)
        XCTAssertTrue(store.thoughts(for: date).isEmpty)
    }

    func testArmingAnotherRowDisarmsTheFirst() throws {
        let defaults = UserDefaults(suiteName: "daylight.diary-delete-confirm.\(UUID().uuidString)")!
        let store = DaylightStore(defaults: defaults)
        let date = LocalDate(year: 2026, month: 8, day: 20)
        store.addThought(for: date, content: "第一条")
        store.addThought(for: date, content: "第二条")
        let thoughts = store.thoughts(for: date)
        let timeline = DiaryThoughtTimelineView()
        timeline.render(thoughts: thoughts)

        let first = try deleteButton(for: thoughts[0].id, in: timeline)
        let second = try deleteButton(for: thoughts[1].id, in: timeline)
        first.mouseDown(with: NSEvent())
        second.mouseDown(with: NSEvent())

        XCTAssertFalse(first.isArmed)
        XCTAssertTrue(second.isArmed)
        XCTAssertEqual(store.thoughts(for: date).count, 2)
    }

    func testRenderClearsArmedState() throws {
        let defaults = UserDefaults(suiteName: "daylight.diary-delete-confirm.\(UUID().uuidString)")!
        let store = DaylightStore(defaults: defaults)
        let date = LocalDate(year: 2026, month: 8, day: 20)
        store.addThought(for: date, content: "重新渲染")
        let thought = try XCTUnwrap(store.thoughts(for: date).first)
        let timeline = DiaryThoughtTimelineView()
        timeline.render(thoughts: [thought])

        let oldButton = try deleteButton(for: thought.id, in: timeline)
        oldButton.mouseDown(with: NSEvent())
        XCTAssertTrue(oldButton.isArmed)

        timeline.render(thoughts: store.thoughts(for: date))

        let newButton = try deleteButton(for: thought.id, in: timeline)
        XCTAssertFalse(newButton.isArmed)
    }

    private func deleteButton(for id: String, in view: NSView) throws -> DiaryThoughtDeleteButton {
        if let button = view as? DiaryThoughtDeleteButton, button.thoughtId == id {
            return button
        }
        for subview in view.subviews {
            if let button = try? deleteButton(for: id, in: subview) {
                return button
            }
        }
        throw XCTSkip("delete control not found for (id)")
    }
}
