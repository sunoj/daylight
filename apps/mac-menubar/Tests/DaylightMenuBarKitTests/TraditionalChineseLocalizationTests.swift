import XCTest
@testable import DaylightMenuBarKit

final class TraditionalChineseLocalizationTests: XCTestCase {
    func testCalendarTermsAndDynamicHolidayNames() {
        let previous = Loc.language
        defer { Loc.language = previous }
        Loc.language = .zhHant

        XCTAssertEqual(L("昼间日历"), "晝間日曆")
        XCTAssertEqual(L("农历与二十四节气"), "農曆與二十四節氣")
        XCTAssertEqual(L("国庆节（调休上班）"), "國慶節（調休上班）")
        XCTAssertEqual(L("丑年干支"), "丑年干支")
        XCTAssertEqual(Loc.weekday(1), "週一")
        XCTAssertEqual(Loc.monthTitle(year: 2026, month: 9), "2026年9月")
    }
}
