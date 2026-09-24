import XCTest
@testable import DaylightMenuBarKit

final class CalendarDayTitleFormatterPerformanceTests: XCTestCase {
    /// One 42-cell month grid must not re-decode the full holiday payload per cell.
  /// Before the DaylightStore decode cache this benchmark measured ~550 ms per grid.
    func testMonthGridTitlePartsStayFastWithLargeHolidayPayload() {
        let defaults = UserDefaults(suiteName: "daylight.perf.\(UUID().uuidString)")!
        let store = DaylightStore(defaults: defaults)

        var bySub: [String: [PublicCalendarDay]] = [:]
        for sub in ["cn", "hk", "th"] {
            bySub[sub] = (0..<400).map { i in
                PublicCalendarDay(
                    date: "2026-\(String(format: "%02d", i % 12 + 1))-\(String(format: "%02d", i % 28 + 1))",
                    type: "holiday",
                    name: "Holiday \(i)",
                    isImportant: false
                )
            }
        }
        for (subId, days) in bySub {
            store.replaceHolidayDays(days, for: subId)
        }
        var settings = UserSettings()
        settings.holidaySubscriptions = ["cn", "hk", "th"].map {
            HolidaySubscription(id: $0, sourceId: $0, customURL: "", colorId: "rust", enabled: true)
        }
        store.saveSettings(settings)
        let model = CalendarModel()
        let formatter = CalendarDayTitleFormatter(store: store, lunarCalendar: LunarCalendar())
        let days = model.monthGrid(year: 2026, month: 8, today: model.today(), weekRule: .iso8601)
        let live = store.settings()

        // Warm decode caches before timing title formatting work.
        for day in days { _ = formatter.titleParts(for: day, settings: live) }

        let iterations = 5
        let start = Date()
        for _ in 0..<iterations {
            for day in days {
                _ = formatter.titleParts(for: day, settings: live)
            }
        }
        let msPerGrid = Date().timeIntervalSince(start) * 1000 / Double(iterations)

        // Per-call JSON decoding produced ~550 ms; cached reads should stay well below that.
        XCTAssertLessThan(msPerGrid, 200, "one grid took \(msPerGrid) ms")
    }
}
