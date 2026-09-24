// Quick-diary save button enable/disable and append behavior.
// Exports: QuickDiaryTests
// Deps: XCTest, AppKit, DaylightMenuBarKit

import AppKit
import XCTest
@testable import DaylightMenuBarKit

final class QuickDiaryTests: XCTestCase {
    func testTodoMarkerParser() {
        XCTAssertEqual(DiaryThoughtCodec.parseInput("[] 买牛奶"), DiaryThoughtDraft(content: "买牛奶", done: false))
        XCTAssertEqual(DiaryThoughtCodec.parseInput("[ ] 买牛奶"), DiaryThoughtDraft(content: "买牛奶", done: false))
        XCTAssertEqual(DiaryThoughtCodec.parseInput("[x] 买牛奶"), DiaryThoughtDraft(content: "买牛奶", done: true))
        XCTAssertEqual(DiaryThoughtCodec.parseInput("[X] 买牛奶"), DiaryThoughtDraft(content: "买牛奶", done: true))
        XCTAssertEqual(DiaryThoughtCodec.parseInput("["), DiaryThoughtDraft(content: "[", done: nil))
        XCTAssertNil(DiaryThoughtCodec.parseInput("[]"))
        XCTAssertNil(DiaryThoughtCodec.parseInput("[ ]   "))
        XCTAssertEqual(DiaryThoughtCodec.parseInput("记下 [] 买牛奶"), DiaryThoughtDraft(content: "记下 [] 买牛奶", done: nil))
    }

    func testQuickDiaryPlaceholderUsesTodayAndSelectedDateInEachLanguage() {
        let selected = LocalDate(year: 2026, month: 8, day: 19)
        let today = LocalDate(year: 2026, month: 8, day: 21)
        let expected: [AppLanguage: (today: String, other: String)] = [
            .zh: ("记一笔今天…", "记一笔 8月19日…"),
            .zhHant: ("記一筆今天…", "記一筆 8月19日…"),
            .en: ("Note today…", "Note Aug 19…"),
            .th: ("บันทึกวันนี้…", "บันทึก 19 ส.ค.…")
        ]
        let original = Loc.language
        defer { Loc.language = original }

        for language in AppLanguage.allCases {
            Loc.language = language
            XCTAssertEqual(Loc.quickDiaryPlaceholder(for: today, today: today), expected[language]?.today)
            XCTAssertEqual(Loc.quickDiaryPlaceholder(for: selected, today: today), expected[language]?.other)
        }
    }

    @MainActor func testSaveButtonDisabledUntilFieldHasContent() {
        let controller = makeController()
        _ = controller.calendarScreen()

        controller.quickDiaryField.stringValue = ""
        controller.controlTextDidChange(change(controller.quickDiaryField))
        XCTAssertEqual(controller.quickDiarySaveButton?.isEnabled, false)

        controller.quickDiaryField.stringValue = "   "
        controller.controlTextDidChange(change(controller.quickDiaryField))
        XCTAssertEqual(controller.quickDiarySaveButton?.isEnabled, false)

        controller.quickDiaryField.stringValue = "[]"
        controller.controlTextDidChange(change(controller.quickDiaryField))
        XCTAssertEqual(controller.quickDiarySaveButton?.isEnabled, false)

        controller.quickDiaryField.stringValue = "hi"
        controller.controlTextDidChange(change(controller.quickDiaryField))
        XCTAssertEqual(controller.quickDiarySaveButton?.isEnabled, true)
    }

    @MainActor func testSaveIgnoresEmptyContent() {
        let store = makeStore()
        let controller = makeController(store: store)
        let date = controller.selectedDate

        controller.quickDiaryField.stringValue = "   "
        controller.saveQuickDiary()
        XCTAssertTrue(store.thoughts(for: date).isEmpty, "blank diary must not be saved")

        controller.quickDiaryField.stringValue = "note"
        controller.saveQuickDiary()
        XCTAssertEqual(store.thoughts(for: date).map(\.content), ["note"])
    }

    @MainActor func testSaveConsumesTodoMarkerAndPreservesCheckedState() {
        let store = makeStore()
        let controller = makeController(store: store)
        let date = controller.selectedDate

        controller.quickDiaryField.stringValue = "[ ] 买牛奶"
        controller.saveQuickDiary()
        controller.quickDiaryField.stringValue = "[X] 已买咖啡"
        controller.saveQuickDiary()

        let thoughts = store.thoughts(for: date)
        XCTAssertEqual(Set(thoughts.map(\.content)), Set(["买牛奶", "已买咖啡"]))
        XCTAssertEqual(thoughts.first { $0.content == "买牛奶" }?.done, false)
        XCTAssertEqual(thoughts.first { $0.content == "已买咖啡" }?.done, true)
    }

    @MainActor func testSecondSaveAppendsThought() {
        let store = makeStore()
        let controller = makeController(store: store)
        let date = controller.selectedDate

        controller.quickDiaryField.stringValue = "first"
        controller.saveQuickDiary()
        controller.quickDiaryField.stringValue = "second"
        controller.saveQuickDiary()

        XCTAssertEqual(Set(store.thoughts(for: date).map(\.content)), Set(["first", "second"]))
    }

    @MainActor private func makeStore() -> DaylightStore {
        DaylightStore(defaults: UserDefaults(suiteName: "daylight.quickdiary.\(UUID().uuidString)")!)
    }

    @MainActor private func makeController(store: DaylightStore? = nil) -> PopoverViewController {
        PopoverViewController(store: store ?? makeStore(), calendarModel: CalendarModel(), onDataChanged: {})
    }

    private func change(_ field: NSTextField) -> Notification {
        Notification(name: NSControl.textDidChangeNotification, object: field)
    }
}
