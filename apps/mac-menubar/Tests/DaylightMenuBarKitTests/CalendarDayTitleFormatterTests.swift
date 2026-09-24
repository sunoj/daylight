// XCTest coverage for calendar day title formatting rules.
// Exports: CalendarDayTitleFormatterTests
// Deps: XCTest, DaylightMenuBarKit, Foundation UserDefaults

import Foundation
import XCTest
@testable import DaylightMenuBarKit

final class CalendarDayTitleFormatterTests: XCTestCase {
    func testWorkdayMarkerDoesNotDependOnLunarPreference() {
        let store = isolatedStore()
        store.replacePublicDays([PublicCalendarDay(date: "2026-10-10", type: "workday", name: "国庆节", isImportant: true)])
        let formatter = CalendarDayTitleFormatter(store: store, lunarCalendar: LunarCalendar())
        let day = CalendarDay(date: LocalDate(year: 2026, month: 10, day: 10), isToday: false, isOutsideMonth: false)
        for enabled in [false, true] {
            XCTAssertTrue(formatter.titleParts(for: day, settings: UserSettings(showLunarDate: enabled)).isWorkday)
        }
    }

    func testTitleIncludesLunarSubtitleWhenEnabled() {
        let formatter = CalendarDayTitleFormatter(store: isolatedStore(), lunarCalendar: LunarCalendar())
        let day = CalendarDay(date: LocalDate(year: 2026, month: 6, day: 29), isToday: false, isOutsideMonth: false)

        let title = formatter.titleParts(for: day, settings: UserSettings(showLunarDate: true))

        XCTAssertEqual(title.primary, "29")
        XCTAssertNotNil(title.secondary)
    }

    func testTitleOmitsLunarSubtitleWhenDisabled() {
        let formatter = CalendarDayTitleFormatter(store: isolatedStore(), lunarCalendar: LunarCalendar())
        let day = CalendarDay(date: LocalDate(year: 2026, month: 6, day: 29), isToday: false, isOutsideMonth: false)

        let title = formatter.titleParts(for: day, settings: UserSettings(showLunarDate: false))

        XCTAssertEqual(title.primary, "29")
        XCTAssertNil(title.secondary)
    }

    func testPublicCalendarNameOverridesLunarSubtitle() {
        let store = isolatedStore()
        store.replacePublicDays([
            PublicCalendarDay(date: "2026-06-29", type: "holiday", name: "Holiday", isImportant: true)
        ])
        let formatter = CalendarDayTitleFormatter(store: store, lunarCalendar: LunarCalendar())
        let day = CalendarDay(date: LocalDate(year: 2026, month: 6, day: 29), isToday: false, isOutsideMonth: false)

        let title = formatter.titleParts(for: day, settings: UserSettings(showLunarDate: true))

        XCTAssertEqual(title.secondary, "Holiday")
        XCTAssertFalse(title.isSolarTerm)
    }

    func testHolidayMatchesMapToSubscriptionColorIds() {
        let store = isolatedStore()
        let cn = HolidaySubscription(id: "cn-1", sourceId: "cn", customURL: "", colorId: "rust", enabled: true)
        let hk = HolidaySubscription(id: "hk-1", sourceId: "hk", customURL: "", colorId: "stone", enabled: true)
        store.saveSettings(UserSettings(holidaySubscriptions: [cn, hk]))
        store.replaceHolidayDays([
            PublicCalendarDay(date: "2026-02-17", type: "holiday", name: "春节", isImportant: true)
        ], for: cn.id)
        store.replaceHolidayDays([
            PublicCalendarDay(date: "2026-02-17", type: "holiday", name: "農曆年初一", isImportant: true)
        ], for: hk.id)
        let formatter = CalendarDayTitleFormatter(store: store, lunarCalendar: LunarCalendar())
        let day = CalendarDay(date: LocalDate(year: 2026, month: 2, day: 17), isToday: false, isOutsideMonth: false)

        let title = formatter.titleParts(for: day, settings: UserSettings(showLunarDate: true))

        XCTAssertEqual(title.holidayColorIds, ["rust", "stone"])
    }

    func testHolidayTooltipListsMatchedSubscriptions() {
        Loc.language = .zh
        let store = isolatedStore()
        let cn = HolidaySubscription(id: "cn-1", sourceId: "cn", customURL: "", colorId: "rust", enabled: true)
        let hk = HolidaySubscription(id: "hk-1", sourceId: "hk", customURL: "", colorId: "stone", enabled: true)
        store.saveSettings(UserSettings(holidaySubscriptions: [cn, hk]))
        store.replaceHolidayDays([
            PublicCalendarDay(date: "2026-02-17", type: "holiday", name: "春节", isImportant: true)
        ], for: cn.id)
        store.replaceHolidayDays([
            PublicCalendarDay(date: "2026-02-17", type: "holiday", name: "農曆年初一", isImportant: true)
        ], for: hk.id)
        let formatter = CalendarDayTitleFormatter(store: store, lunarCalendar: LunarCalendar())
        let day = CalendarDay(date: LocalDate(year: 2026, month: 2, day: 17), isToday: false, isOutsideMonth: false)

        let title = formatter.titleParts(for: day, settings: UserSettings(showLunarDate: true))

        XCTAssertEqual(title.holidayTooltip, "春节 · 中国大陆\n農曆年初一 · 中国香港特别行政区")
    }

    func testHolidayTooltipIsNilWhenDateHasNoHolidays() {
        let formatter = CalendarDayTitleFormatter(store: isolatedStore(), lunarCalendar: LunarCalendar())
        let day = CalendarDay(date: LocalDate(year: 2026, month: 6, day: 29), isToday: false, isOutsideMonth: false)

        let title = formatter.titleParts(for: day, settings: UserSettings(showLunarDate: false))

        XCTAssertNil(title.holidayTooltip)
    }

    private func isolatedStore() -> DaylightStore {
        let suiteName = "CalendarDayTitleFormatterTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return DaylightStore(defaults: defaults)
    }
}
