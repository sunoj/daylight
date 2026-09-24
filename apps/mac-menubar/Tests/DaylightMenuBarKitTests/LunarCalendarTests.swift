// XCTest coverage for lunar date and solar term accuracy.
// Exports: LunarCalendarTests
// Deps: XCTest, DaylightMenuBarKit

import XCTest
@testable import DaylightMenuBarKit

final class LunarCalendarTests: XCTestCase {
    private let calendar = LunarCalendar()

    func testSolarTermsFallOnCorrectDay() {
        // Known China-time solar term dates, including years the old linear
        // formula and 公式法 got wrong, and both table edges. Golden values
        // cross-checked against astronomy-engine and 寿星天文历.
        let cases: [(LocalDate, String)] = [
            (LocalDate(year: 2026, month: 1, day: 5), "小寒"),
            (LocalDate(year: 2026, month: 2, day: 4), "立春"),
            (LocalDate(year: 2026, month: 2, day: 18), "雨水"),
            (LocalDate(year: 2026, month: 3, day: 20), "春分"),
            (LocalDate(year: 2026, month: 7, day: 7), "小暑"),
            (LocalDate(year: 2026, month: 7, day: 23), "大暑"),
            (LocalDate(year: 2026, month: 12, day: 22), "冬至"),
            (LocalDate(year: 2025, month: 2, day: 3), "立春"),
            (LocalDate(year: 2000, month: 1, day: 6), "小寒"),
            (LocalDate(year: 1950, month: 4, day: 20), "谷雨"),
            (LocalDate(year: 1949, month: 1, day: 5), "小寒"),
            (LocalDate(year: 2100, month: 3, day: 20), "春分"),
            (LocalDate(year: 2100, month: 12, day: 22), "冬至")
        ]
        for (date, term) in cases {
            XCTAssertEqual(calendar.solarTerm(for: date), term, "\(date.key)")
        }
        // The term also rides along on the lunar date when one is available.
        XCTAssertEqual(calendar.lunarDate(for: LocalDate(year: 2026, month: 1, day: 5))?.solarTerm, "小寒")
    }

    func testNonTermDayHasNoSolarTerm() {
        // 2026-07-02 is 五月十八, not a solar term (regression: was wrongly 小暑).
        let lunar = calendar.lunarDate(for: LocalDate(year: 2026, month: 7, day: 2))
        XCTAssertNil(lunar?.solarTerm)
        XCTAssertEqual(lunar?.dayName, "十八")

        // 2026-02-19 is the day after 雨水 (the old formula placed the term here).
        XCTAssertNil(calendar.lunarDate(for: LocalDate(year: 2026, month: 2, day: 19))?.solarTerm)
    }

    func testLeapMonthsCarryPrefixAndCorrectNumber() {
        let leap2025 = calendar.lunarDate(for: LocalDate(year: 2025, month: 7, day: 25))
        XCTAssertEqual(leap2025?.monthName, "闰六")
        XCTAssertEqual(leap2025?.dayName, "初一")
        XCTAssertEqual(leap2025?.yearName, "乙巳")

        let leap1987 = calendar.lunarDate(for: LocalDate(year: 1987, month: 8, day: 1))
        XCTAssertEqual(leap1987?.monthName, "闰六")
        XCTAssertEqual(leap1987?.dayName, "初七")

        let leap2023 = calendar.lunarDate(for: LocalDate(year: 2023, month: 3, day: 22))
        XCTAssertEqual(leap2023?.monthName, "闰二")
        XCTAssertEqual(leap2023?.dayName, "初一")

        // The month after the leap month keeps its own number (七月, not 六月).
        let after = calendar.lunarDate(for: LocalDate(year: 2025, month: 8, day: 23))
        XCTAssertEqual(after?.monthName, "七")
        XCTAssertEqual(after?.dayName, "初一")
    }

    func testCorrectedTableEntries() {
        // 1996: 六月初一 = 07-16 and 中秋 八月十五 = 09-27 (the widely
        // circulated table is off by one day for months 5–8).
        let june1996 = calendar.lunarDate(for: LocalDate(year: 1996, month: 7, day: 16))
        XCTAssertEqual(june1996?.monthName, "六")
        XCTAssertEqual(june1996?.dayName, "初一")
        let midAutumn1996 = calendar.lunarDate(for: LocalDate(year: 1996, month: 9, day: 27))
        XCTAssertEqual(midAutumn1996?.monthName, "八")
        XCTAssertEqual(midAutumn1996?.dayName, "十五")

        // 2060: 四月初一 = 04-30 (new moon 18:11 CST).
        let april2060 = calendar.lunarDate(for: LocalDate(year: 2060, month: 4, day: 30))
        XCTAssertEqual(april2060?.monthName, "四")
        XCTAssertEqual(april2060?.dayName, "初一")
    }

    func testSpringFestivalBoundaries() {
        // New-moon-near-midnight years where ICU disagrees but the table
        // matches the astronomical instant and the published calendar.
        let spring1954 = calendar.lunarDate(for: LocalDate(year: 1954, month: 2, day: 3))
        XCTAssertEqual(spring1954?.monthName, "正")
        XCTAssertEqual(spring1954?.dayName, "初一")
        let spring2027 = calendar.lunarDate(for: LocalDate(year: 2027, month: 2, day: 6))
        XCTAssertEqual(spring2027?.monthName, "正")
        XCTAssertEqual(spring2027?.dayName, "初一")
    }

    func testRangeEdges() {
        // The table starts at lunar new year 1949 (1949-01-29).
        XCTAssertNil(calendar.lunarDate(for: LocalDate(year: 1949, month: 1, day: 28)))
        let start = calendar.lunarDate(for: LocalDate(year: 1949, month: 1, day: 29))
        XCTAssertEqual(start?.monthName, "正")
        XCTAssertEqual(start?.dayName, "初一")

        let end = calendar.lunarDate(for: LocalDate(year: 2100, month: 12, day: 31))
        XCTAssertEqual(end?.yearName, "庚申")
        XCTAssertEqual(end?.monthName, "腊")
        XCTAssertEqual(end?.dayName, "初一")
    }
}
