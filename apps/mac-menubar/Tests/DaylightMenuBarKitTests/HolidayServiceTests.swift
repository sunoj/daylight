// XCTest coverage for iCal parsing (contract with the holidays-ical feed).
// Exports: HolidayServiceTests
// Deps: XCTest, DaylightMenuBarKit

import XCTest
@testable import DaylightMenuBarKit

final class HolidayServiceTests: XCTestCase {
    func testAdjustedWorkdaysKeepTheirTypeAndDoNotLeakIntoOtherEvents() {
        let days = HolidayService.parse(ics: [
            "BEGIN:VCALENDAR", "BEGIN:VEVENT", "DTSTART;VALUE=DATE:20261010",
            "X-DAYLIGHT-DAY-TYPE:WORKDAY", "SUMMARY:国庆节（调休上班）", "END:VEVENT",
            "BEGIN:VEVENT", "DTSTART;VALUE=DATE:20261011", "SUMMARY:External holiday", "END:VEVENT",
            "BEGIN:VEVENT", "DTSTART;VALUE=DATE:20261012", "X-DAYLIGHT-DAY-TYPE:UNKNOWN", "END:VEVENT",
            "END:VCALENDAR"
        ].joined(separator: "\r\n"))
        XCTAssertEqual(days.map(\.type), ["workday", "holiday", "holiday"])
        XCTAssertEqual(days.first?.name, "国庆节")
    }

    override func tearDown() {
        Loc.language = .zh
        super.tearDown()
    }

    func testParsesAllDayEventsFromHostedFeed() {
        // Matches the VEVENT shape emitted by apps/holidays-ical.
        let ics = [
            "BEGIN:VCALENDAR", "VERSION:2.0",
            "BEGIN:VEVENT",
            "DTSTART;VALUE=DATE:20260101",
            "DTEND;VALUE=DATE:20260102",
            "SUMMARY:元旦",
            "END:VEVENT",
            "BEGIN:VEVENT",
            "DTSTART;VALUE=DATE:20260219",
            "DTEND;VALUE=DATE:20260221",
            "SUMMARY:春节",
            "END:VEVENT",
            "END:VCALENDAR"
        ].joined(separator: "\r\n")

        let days = HolidayService.parse(ics: ics)

        XCTAssertEqual(days.count, 3) // 元旦 (1) + 春节 span 02-19..02-20 (2)
        XCTAssertEqual(days[0].date, "2026-01-01")
        XCTAssertEqual(days[0].name, "元旦")
        XCTAssertEqual(days[0].type, "holiday")
        XCTAssertEqual(days[1].date, "2026-02-19")
        XCTAssertEqual(days[2].date, "2026-02-20")
    }

    func testParseUnfoldsLinesAndUnescapesText() {
        // RFC 5545 folded SUMMARY (as in the GovHK feed) plus escaped TEXT and
        // a DTEND that is not after DTSTART.
        let ics = [
            "BEGIN:VCALENDAR",
            "X-WR-CALNAME:Fest\\, Days",
            "BEGIN:VEVENT",
            "SUMMARY:The day following the Chinese Mid-Autumn Fe",
            " stival\\, observed",
            "DTSTART;VALUE=DATE:20261001",
            "END:VEVENT",
            "BEGIN:VEVENT",
            "SUMMARY:Inverted range",
            "DTSTART;VALUE=DATE:20261005",
            "DTEND;VALUE=DATE:20261005",
            "END:VEVENT",
            "END:VCALENDAR"
        ].joined(separator: "\r\n")

        let days = HolidayService.parse(ics: ics)

        XCTAssertEqual(HolidayService.parseCalendarName(ics: ics), "Fest, Days")
        XCTAssertEqual(days.count, 2)
        XCTAssertEqual(days[0].date, "2026-10-01")
        XCTAssertEqual(days[0].name, "The day following the Chinese Mid-Autumn Festival, observed")
        XCTAssertEqual(days[1].date, "2026-10-05")
        XCTAssertEqual(days[1].name, "Inverted range")
    }

    func testStripSharedFeedPrefixWhenEveryEventHasSamePrefix() {
        let days = [
            holiday(name: "Thailand: Songkran"),
            holiday(name: "Thailand: Chakri Day", date: "2026-04-06")
        ]

        let stripped = HolidayService.stripSharedFeedPrefix(from: days, eventNames: days.map(\.name))

        XCTAssertEqual(stripped.map(\.name), ["Songkran", "Chakri Day"])
    }

    func testStripSharedFeedPrefixKeepsNamesWhenOneEventLacksPrefix() {
        let days = [
            holiday(name: "Thailand: Songkran"),
            holiday(name: "Chakri Day", date: "2026-04-06")
        ]

        let stripped = HolidayService.stripSharedFeedPrefix(from: days, eventNames: days.map(\.name))

        XCTAssertEqual(stripped.map(\.name), ["Thailand: Songkran", "Chakri Day"])
    }

    func testStripSharedFeedPrefixKeepsSingleEventFeed() {
        let days = [holiday(name: "Thailand: Songkran")]

        let stripped = HolidayService.stripSharedFeedPrefix(from: days, eventNames: days.map(\.name))

        XCTAssertEqual(stripped.map(\.name), ["Thailand: Songkran"])
    }

    func testStripSharedFeedPrefixNeverStripsNameToEmpty() {
        let days = [
            holiday(name: "Thailand: "),
            holiday(name: "Thailand: Songkran", date: "2026-04-13")
        ]

        let stripped = HolidayService.stripSharedFeedPrefix(from: days, eventNames: days.map(\.name))

        XCTAssertEqual(stripped.map(\.name), ["Thailand: ", "Thailand: Songkran"])
    }

    func testStripSharedFeedPrefixKeepsNameDetailsAfterFirstDelimiter() {
        let days = [
            holiday(name: "Thailand: Chinese New Year (Regional Holiday): Day 1"),
            holiday(name: "Thailand: Chinese New Year (Regional Holiday): Day 2", date: "2026-02-18")
        ]

        let stripped = HolidayService.stripSharedFeedPrefix(from: days, eventNames: days.map(\.name))

        XCTAssertEqual(stripped.map(\.name), [
            "Chinese New Year (Regional Holiday): Day 1",
            "Chinese New Year (Regional Holiday): Day 2"
        ])
    }

    func testParseCalendarNameReadsPlainValue() {
        let ics = ["BEGIN:VCALENDAR", "X-WR-CALNAME:Thailand Holidays", "END:VCALENDAR"].joined(separator: "\r\n")

        XCTAssertEqual(HolidayService.parseCalendarName(ics: ics), "Thailand Holidays")
    }

    func testParseCalendarNameUnfoldsFoldedValue() {
        let ics = [
            "BEGIN:VCALENDAR",
            "X-WR-CALNAME:Thailand Public",
            " Holidays",
            "END:VCALENDAR"
        ].joined(separator: "\r\n")

        XCTAssertEqual(HolidayService.parseCalendarName(ics: ics), "Thailand PublicHolidays")
    }

    func testParseCalendarNameAllowsParameters() {
        let ics = ["BEGIN:VCALENDAR", "X-WR-CALNAME;VALUE=TEXT:香港公眾假期", "END:VCALENDAR"].joined(separator: "\n")

        XCTAssertEqual(HolidayService.parseCalendarName(ics: ics), "香港公眾假期")
    }

    func testParseCalendarNameReturnsNilWhenAbsent() {
        let ics = ["BEGIN:VCALENDAR", "VERSION:2.0", "END:VCALENDAR"].joined(separator: "\r\n")

        XCTAssertNil(HolidayService.parseCalendarName(ics: ics))
    }

    func testResolvedCustomNameKeepsTypedName() {
        let subscription = HolidaySubscription(
            id: "custom-1",
            sourceId: "custom",
            customURL: "https://officeholidays.com/ics/thailand",
            colorId: "rust",
            enabled: true,
            name: " My Feed "
        )

        let name = HolidayService.resolvedCustomName(
            subscription: subscription,
            calendarName: "Thailand Holidays",
            url: URL(string: subscription.customURL)
        )

        XCTAssertEqual(name, "My Feed")
    }

    func testResolvedCustomNameUsesFeedNameWhenTypedNameIsBlank() {
        let subscription = HolidaySubscription(
            id: "custom-1",
            sourceId: "custom",
            customURL: "https://officeholidays.com/ics/thailand",
            colorId: "rust",
            enabled: true,
            name: " "
        )

        let name = HolidayService.resolvedCustomName(
            subscription: subscription,
            calendarName: " Thailand Holidays ",
            url: URL(string: subscription.customURL)
        )

        XCTAssertEqual(name, "Thailand Holidays")
    }

    func testResolvedCustomNameFallsBackToHost() {
        let subscription = HolidaySubscription(
            id: "custom-1",
            sourceId: "custom",
            customURL: "https://officeholidays.com/ics/thailand",
            colorId: "rust",
            enabled: true
        )

        let name = HolidayService.resolvedCustomName(
            subscription: subscription,
            calendarName: nil,
            url: URL(string: subscription.customURL)
        )

        XCTAssertEqual(name, "officeholidays.com")
    }

    func testFormatsPresetCountsByLanguage() {
        Loc.language = .zh
        XCTAssertEqual(HolidaySourceCountFormatter.string(for: .daysPerYear(13)), "13 天 / 年")
        XCTAssertEqual(HolidaySourceCountFormatter.string(for: .days(17)), "17 天")

        Loc.language = .en
        XCTAssertEqual(HolidaySourceCountFormatter.string(for: .daysPerYear(13)), "13 days / year")
        XCTAssertEqual(HolidaySourceCountFormatter.string(for: .days(17)), "17 days")

        Loc.language = .th
        XCTAssertEqual(HolidaySourceCountFormatter.string(for: .daysPerYear(13)), "13 วัน / ปี")
        XCTAssertEqual(HolidaySourceCountFormatter.string(for: .days(17)), "17 วัน")
        XCTAssertEqual(HolidaySourceCountFormatter.string(for: .unknown), "—")
        XCTAssertEqual(HolidaySourceCountFormatter.string(for: .none), "")
    }

    private func holiday(name: String?, date: String = "2026-04-13") -> PublicCalendarDay {
        PublicCalendarDay(date: date, type: "holiday", name: name, isImportant: true)
    }
}
