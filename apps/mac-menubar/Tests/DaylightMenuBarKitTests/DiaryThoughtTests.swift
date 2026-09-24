// Diary thought migration and append behavior for DaylightStore.
// Exports: DiaryThoughtTests
// Deps: XCTest, DaylightMenuBarKit, Foundation

import Foundation
import XCTest
@testable import DaylightMenuBarKit

final class DiaryThoughtTests: XCTestCase {
    func testLegacyPayloadDecodesToOneThoughtWithTimestamp() throws {
        let defaults = isolatedDefaults()
        let payload = """
        [
          {
            "date": "2024-02-10",
            "content": "Old note",
            "updatedAt": "2024-02-10T08:15:30Z"
          }
        ]
        """.data(using: .utf8)!
        defaults.set(payload, forKey: "diaryEntries")

        let thoughts = DaylightStore(defaults: defaults).thoughts(for: LocalDate(year: 2024, month: 2, day: 10))
        XCTAssertEqual(thoughts.count, 1)
        XCTAssertEqual(thoughts[0].id, DiaryThoughtCodec.legacyId(for: "2024-02-10"))
        XCTAssertEqual(thoughts[0].content, "Old note")
        XCTAssertEqual(thoughts[0].createdAt, "2024-02-10T08:15:30Z")
        XCTAssertEqual(thoughts[0].updatedAt, "2024-02-10T08:15:30Z")
    }

    func testNewShapeRoundTripsUnchanged() throws {
        let defaults = isolatedDefaults()
        let payload = """
        [
          {
            "id": "thought-1",
            "date": "2024-02-10",
            "content": "Fresh",
            "createdAt": "2024-02-11T10:00:00.000Z",
            "updatedAt": "2024-02-11T10:00:00.000Z"
          }
        ]
        """.data(using: .utf8)!
        defaults.set(payload, forKey: "diaryEntries")

        let thoughts = DaylightStore(defaults: defaults).thoughts(for: LocalDate(year: 2024, month: 2, day: 10))
        XCTAssertEqual(thoughts.count, 1)
        XCTAssertEqual(thoughts[0].id, "thought-1")
        XCTAssertEqual(thoughts[0].createdAt, "2024-02-11T10:00:00.000Z")
        XCTAssertNil(thoughts[0].done)
    }

    func testTodoRoundTripsThroughStoreAndToggleUpdatesIt() {
        let store = DaylightStore(defaults: isolatedDefaults())
        let date = LocalDate(year: 2026, month: 7, day: 24)
        store.addThought(for: date, content: "Buy milk", done: false)

        guard let saved = store.thoughts(for: date).first else { return XCTFail("todo was not saved") }
        XCTAssertEqual(saved.done, false)
        let previousUpdatedAt = saved.updatedAt

        store.toggleThought(id: saved.id)

        let toggled = store.thoughts(for: date).first
        XCTAssertEqual(toggled?.done, true)
        XCTAssertNotEqual(toggled?.updatedAt, previousUpdatedAt)
    }

    func testSavingTwiceSameDayCreatesTwoThoughts() {
        let store = DaylightStore(defaults: isolatedDefaults())
        let date = LocalDate(year: 2026, month: 7, day: 24)
        store.addThought(for: date, content: "first")
        store.addThought(for: date, content: "second")

        let thoughts = store.thoughts(for: date)
        XCTAssertEqual(thoughts.count, 2)
        XCTAssertEqual(Set(thoughts.map(\.content)), Set(["first", "second"]))
    }

    func testThoughtsForDateReturnNewestFirst() {
        let defaults = isolatedDefaults()
        let payload = """
        [
          {
            "id": "older",
            "date": "2026-07-24",
            "content": "first",
            "createdAt": "2026-07-24T08:00:00.000Z",
            "updatedAt": "2026-07-24T08:00:00.000Z"
          },
          {
            "id": "newer",
            "date": "2026-07-24",
            "content": "second",
            "createdAt": "2026-07-24T12:00:00.000Z",
            "updatedAt": "2026-07-24T12:00:00.000Z"
          }
        ]
        """.data(using: .utf8)!
        defaults.set(payload, forKey: "diaryEntries")

        let thoughts = DaylightStore(defaults: defaults).thoughts(for: LocalDate(year: 2026, month: 7, day: 24))
        XCTAssertEqual(thoughts.map(\.id), ["newer", "older"])
    }

    func testDeleteThoughtLeavesOthersOnSameDayIntact() {
        let store = DaylightStore(defaults: isolatedDefaults())
        let date = LocalDate(year: 2026, month: 7, day: 24)
        store.addThought(for: date, content: "keep")
        store.addThought(for: date, content: "remove")
        // Target by content, not by position: this test is about deletion, and
        // pinning it to an ordering made it fail whenever the two shared a
        // millisecond.
        let removeId = store.thoughts(for: date).first { $0.content == "remove" }?.id
        XCTAssertNotNil(removeId)

        store.deleteThought(id: removeId!)
        let remaining = store.thoughts(for: date)
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining[0].content, "keep")
    }

    func testTimelineDisplaySortsOldestFirst() {
        let thoughts = [
            DiaryThought(id: "newer", date: "2026-07-24", content: "second", createdAt: "2026-07-24T12:00:00.000Z", updatedAt: "2026-07-24T12:00:00.000Z"),
            DiaryThought(id: "older", date: "2026-07-24", content: "first", createdAt: "2026-07-24T08:00:00.000Z", updatedAt: "2026-07-24T08:00:00.000Z")
        ]
        XCTAssertEqual(DiaryThoughtCodec.sortedOldestFirst(thoughts).map(\.id), ["older", "newer"])
    }

    private func isolatedDefaults() -> UserDefaults {
        UserDefaults(suiteName: "daylight.diarythought.\(UUID().uuidString)")!
    }
}
