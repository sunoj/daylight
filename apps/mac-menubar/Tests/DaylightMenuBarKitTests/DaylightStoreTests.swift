// XCTest coverage for UserDefaults-backed native persistence behavior.
// Exports: DaylightStoreTests
// Deps: XCTest, DaylightMenuBarKit, Foundation UserDefaults, CoreLocation

import CoreLocation
import Foundation
import XCTest
@testable import DaylightMenuBarKit

final class DaylightStoreTests: XCTestCase {
    func testDefaultSettingsUseIsoCalendarWithVisibleLunarAndWeekNumbers() {
        let settings = DaylightStore(defaults: isolatedDefaults()).settings()

        XCTAssertTrue(settings.showLunarDate)
        XCTAssertTrue(settings.showWeekNumbers)
        XCTAssertEqual(settings.colorScheme, "system")
        XCTAssertEqual(settings.weekRule, .iso8601)
    }

    func testSettingsPreservePresentValuesWhenStoredPayloadOmitsKeys() {
        let defaults = isolatedDefaults()
        let payload = """
        {
          "showLunarDate": false,
          "statusSegments": ["time", "weekday"]
        }
        """.data(using: .utf8)!
        defaults.set(payload, forKey: "settings")

        let settings = DaylightStore(defaults: defaults).settings()

        XCTAssertFalse(settings.showLunarDate)
        XCTAssertEqual(settings.statusSegments, ["time", "weekday"])
        XCTAssertEqual(settings.hiddenCalendarIds, [])
    }

    func testHiddenCalendarIdsRoundTripThroughStore() {
        let defaults = isolatedDefaults()
        let store = DaylightStore(defaults: defaults)
        var settings = store.settings()
        settings.hiddenCalendarIds = ["work", "personal"]
        store.saveSettings(settings)

        XCTAssertEqual(store.settings().hiddenCalendarIds, ["work", "personal"])
    }

    func testSettingsWrittenBeforeHiddenCalendarIdsStillDecode() {
        let defaults = isolatedDefaults()
        let payload = """
        {
          "systemCalendarEnabled": true,
          "showLunarDate": true
        }
        """.data(using: .utf8)!
        defaults.set(payload, forKey: "settings")

        let settings = DaylightStore(defaults: defaults).settings()

        XCTAssertTrue(settings.systemCalendarEnabled)
        XCTAssertEqual(settings.hiddenCalendarIds, [])
    }

    func testSettingsWrittenByEarlierVersionStillDecode() {
        let defaults = isolatedDefaults()
        let payload = """
        {
          "showLunarDate": false,
          "showWeekNumbers": false,
          "calendarType": "us",
          "uiMode": "sol",
          "show\\u0044ouble\\u0043alendar": true
        }
        """.data(using: .utf8)!
        defaults.set(payload, forKey: "settings")

        let settings = DaylightStore(defaults: defaults).settings()

        XCTAssertFalse(settings.showLunarDate)
        XCTAssertFalse(settings.showWeekNumbers)
        XCTAssertEqual(settings.weekRule, .us)
        XCTAssertFalse(settings.isLunaUI)
    }

    func testLegacyHolidaySubscriptionMigratesToRustSubscription() {
        let defaults = isolatedDefaults()
        let payload = """
        {
          "holidaySubscribed": true,
          "holidaySource": "cn",
          "holidayURL": "https://example.test/cn.ics"
        }
        """.data(using: .utf8)!
        defaults.set(payload, forKey: "settings")

        let settings = DaylightStore(defaults: defaults).settings()

        XCTAssertEqual(settings.holidaySubscriptions, [
            HolidaySubscription(id: "legacy-cn", sourceId: "cn", customURL: "https://example.test/cn.ics", colorId: "rust", enabled: true)
        ])
    }

    func testExistingHolidaySubscriptionsAreLeftAlone() {
        let defaults = isolatedDefaults()
        let payload = """
        {
          "holidaySubscribed": true,
          "holidaySource": "cn",
          "holidaySubscriptions": [
            {"id": "hk-1", "sourceId": "hk", "customURL": "", "colorId": "stone", "enabled": true}
          ]
        }
        """.data(using: .utf8)!
        defaults.set(payload, forKey: "settings")

        let settings = DaylightStore(defaults: defaults).settings()

        XCTAssertEqual(settings.holidaySubscriptions, [
            HolidaySubscription(id: "hk-1", sourceId: "hk", customURL: "", colorId: "stone", enabled: true)
        ])
    }

    func testHolidaySubscriptionWithoutNameDecodesWithEmptyName() {
        let defaults = isolatedDefaults()
        let payload = """
        {
          "holidaySubscriptions": [
            {"id": "custom-1", "sourceId": "custom", "customURL": "https://example.test/feed.ics", "colorId": "rust", "enabled": true}
          ]
        }
        """.data(using: .utf8)!
        defaults.set(payload, forKey: "settings")

        let settings = DaylightStore(defaults: defaults).settings()

        XCTAssertEqual(settings.holidaySubscriptions.count, 1)
        XCTAssertEqual(settings.holidaySubscriptions[0].id, "custom-1")
        XCTAssertEqual(settings.holidaySubscriptions[0].name, "")
    }

    func testHolidayDaysAreStoredPerSubscriptionAndOrderedBySettings() {
        let store = DaylightStore(defaults: isolatedDefaults())
        let cn = HolidaySubscription(id: "cn-1", sourceId: "cn", customURL: "", colorId: "rust", enabled: true)
        let hk = HolidaySubscription(id: "hk-1", sourceId: "hk", customURL: "", colorId: "stone", enabled: true)
        store.saveSettings(UserSettings(holidaySubscriptions: [hk, cn]))
        store.replaceHolidayDays([
            PublicCalendarDay(date: "2026-02-17", type: "holiday", name: "春节", isImportant: true),
            PublicCalendarDay(date: "2026-02-18", type: "holiday", name: "春节", isImportant: true)
        ], for: cn.id)
        store.replaceHolidayDays([
            PublicCalendarDay(date: "2026-02-17", type: "holiday", name: "農曆年初一", isImportant: true)
        ], for: hk.id)

        let hits = store.holidayHits(for: LocalDate(year: 2026, month: 2, day: 17))

        XCTAssertEqual(hits.map(\.subscription.id), ["hk-1", "cn-1"])
        XCTAssertEqual(hits.map(\.day.name), ["農曆年初一", "春节"])

        store.removeHolidayDays(for: hk.id)

        let remaining = store.holidayHits(for: LocalDate(year: 2026, month: 2, day: 17))
        XCTAssertEqual(remaining.map(\.subscription.id), ["cn-1"])
        XCTAssertEqual(store.holidayHits(for: LocalDate(year: 2026, month: 2, day: 18)).map(\.subscription.id), ["cn-1"])
    }

    func testHolidayDetailEntriesFollowSubscriptionOrderWithColorAndSource() {
        let store = DaylightStore(defaults: isolatedDefaults())
        let cn = HolidaySubscription(id: "cn-1", sourceId: "cn", customURL: "", colorId: "rust", enabled: true)
        let hk = HolidaySubscription(id: "hk-1", sourceId: "hk", customURL: "", colorId: "stone", enabled: true)
        store.saveSettings(UserSettings(holidaySubscriptions: [hk, cn]))
        store.replaceHolidayDays([
            PublicCalendarDay(date: "2026-02-17", type: "holiday", name: "春节", isImportant: true)
        ], for: cn.id)
        store.replaceHolidayDays([
            PublicCalendarDay(date: "2026-02-17", type: "holiday", name: "農曆年初一", isImportant: true)
        ], for: hk.id)

        let entries = HolidayDetailEntries.entries(for: LocalDate(year: 2026, month: 2, day: 17), store: store)

        XCTAssertEqual(entries.map(\.day.name), ["農曆年初一", "春节"])
        XCTAssertEqual(entries.map(\.colorId), ["stone", "rust"])
        XCTAssertEqual(entries.map(\.sourceId), ["hk", "cn"])
    }

    func testHolidayDetailEntriesUseCustomSubscriptionName() {
        let store = DaylightStore(defaults: isolatedDefaults())
        let custom = HolidaySubscription(
            id: "custom-1",
            sourceId: "custom",
            customURL: "https://example.test/feed.ics",
            colorId: "rust",
            enabled: true,
            name: "Thailand Holidays"
        )
        store.saveSettings(UserSettings(holidaySubscriptions: [custom]))
        store.replaceHolidayDays([
            PublicCalendarDay(date: "2026-04-13", type: "holiday", name: "Songkran", isImportant: true)
        ], for: custom.id)

        let entries = HolidayDetailEntries.entries(for: LocalDate(year: 2026, month: 4, day: 13), store: store)

        XCTAssertEqual(entries.map(\.sourceName), ["Thailand Holidays"])
    }

    func testHolidayDetailEntriesAreEmptyWhenDateHasNoHoliday() {
        let store = DaylightStore(defaults: isolatedDefaults())
        let cn = HolidaySubscription(id: "cn-1", sourceId: "cn", customURL: "", colorId: "rust", enabled: true)
        store.saveSettings(UserSettings(holidaySubscriptions: [cn]))
        store.replaceHolidayDays([
            PublicCalendarDay(date: "2026-02-17", type: "holiday", name: "春节", isImportant: true)
        ], for: cn.id)
        store.replacePublicDays([
            PublicCalendarDay(date: "2026-05-01", type: "holiday", name: "Labour Day", isImportant: true)
        ])

        let entries = HolidayDetailEntries.entries(for: LocalDate(year: 2026, month: 6, day: 1), store: store)

        XCTAssertTrue(entries.isEmpty)
    }

    func testHolidayDetailEntriesDeduplicateRemoteDayMatchingSubscriptionName() {
        let store = DaylightStore(defaults: isolatedDefaults())
        let cn = HolidaySubscription(id: "cn-1", sourceId: "cn", customURL: "", colorId: "rust", enabled: true)
        store.saveSettings(UserSettings(holidaySubscriptions: [cn]))
        store.replaceHolidayDays([
            PublicCalendarDay(date: "2026-02-17", type: "holiday", name: "春节", isImportant: true)
        ], for: cn.id)
        store.replacePublicDays([
            PublicCalendarDay(date: "2026-02-17", type: "holiday", name: "春节", isImportant: true)
        ])

        let entries = HolidayDetailEntries.entries(for: LocalDate(year: 2026, month: 2, day: 17), store: store)

        XCTAssertEqual(entries.map(\.day.name), ["春节"])
        XCTAssertEqual(entries.map(\.isRemote), [false])
    }

    func testFreshCachedObserverLocationReturnsYoungerThanSevenDays() {
        let store = DaylightStore(defaults: isolatedDefaults())
        let now = Date(timeIntervalSince1970: 1_000_000)
        let location = ObserverLocation(latitudeDegrees: 51.5, longitudeDegrees: -0.1)

        store.saveObserverLocation(location, timestamp: now.addingTimeInterval(-(LocationService.observerLocationCacheTTL - 1)))

        XCTAssertEqual(LocationService.freshCachedObserverLocation(from: store, now: now), location)
    }

    func testCachedObserverLocationAtSevenDaysIsStale() {
        let store = DaylightStore(defaults: isolatedDefaults())
        let now = Date(timeIntervalSince1970: 1_000_000)
        let location = ObserverLocation(latitudeDegrees: 35.7, longitudeDegrees: 139.7)

        store.saveObserverLocation(location, timestamp: now.addingTimeInterval(-LocationService.observerLocationCacheTTL))

        XCTAssertNil(LocationService.freshCachedObserverLocation(from: store, now: now))
    }

    func testObserverLocationCacheRoundTripsLatitudeAndLongitude() {
        let store = DaylightStore(defaults: isolatedDefaults())
        let timestamp = Date(timeIntervalSince1970: 1_234_567)

        store.saveObserverLocation(ObserverLocation(latitudeDegrees: -33.86, longitudeDegrees: 151.21), timestamp: timestamp)

        let cached = store.cachedObserverLocation()
        XCTAssertEqual(cached?.latitude, -33.86)
        XCTAssertEqual(cached?.longitude, 151.21)
        XCTAssertEqual(cached?.timestamp, timestamp)
    }

    func testDeniedLocationNeverUsesFreshCache() {
        let location = ObserverLocation(latitudeDegrees: 48.85, longitudeDegrees: 2.35)

        let resolution = LocationService.resolution(for: .denied, cachedLocation: location)

        XCTAssertEqual(resolution, .unavailable("Location permission is disabled"))
    }

    func testWriteInvalidatesCachedSettingsSoNextReadReflectsChange() {
        let defaults = isolatedDefaults()
        let store = DaylightStore(defaults: defaults)
        var settings = store.settings()
        settings.showLunarDate = false
        store.saveSettings(settings)

        XCTAssertFalse(store.settings().showLunarDate)
    }

    func testClearObserverLocationRemovesCachedValue() {
        let store = DaylightStore(defaults: isolatedDefaults())
        store.saveObserverLocation(ObserverLocation(latitudeDegrees: 1, longitudeDegrees: 2))

        XCTAssertNotNil(store.cachedObserverLocation())

        store.clearObserverLocation()

        XCTAssertNil(store.cachedObserverLocation())
    }

    private func isolatedDefaults() -> UserDefaults {
        let suiteName = "DaylightStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
