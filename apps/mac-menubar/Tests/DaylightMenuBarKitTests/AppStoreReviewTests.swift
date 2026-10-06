import AppKit
import CoreLocation
import XCTest
@testable import DaylightMenuBarKit

/// Guards for the 2026-10 App Store review audit (Guidelines 2.1, 4, 5.1.1).
/// LocalizationComplianceTests covers strings and permission prompts; this file
/// covers behaviour a reviewer exercises.
final class AppStoreReviewTests: XCTestCase {
    private var previousLanguage = Loc.language
    override func setUp() { previousLanguage = Loc.language }
    override func tearDown() { Loc.language = previousLanguage }

    // MARK: English first launch shows English (Guideline 4)

    @MainActor func testEnglishFirstLaunchRendersNoChineseOnAnyScreen() throws {
        let screens: [(String, PopoverScreen?)] = [
            ("luna", nil), ("sol", nil), ("sol", .settings), ("sol", .holidays),
            ("sol", .statusEditor), ("sol", .systemCalendar), ("sol", .locationPrompt)
        ]
        // The language picker names each language in itself (简 / 繁).
        let endonyms = Set(AppLanguage.allCases.map(\.displayName))
        for (mode, screen) in screens {
            let controller = try englishController(mode: mode)
            if let screen { controller.show(screen) }
            RunLoop.main.run(until: Date().addingTimeInterval(0.1))
            let texts = visibleText(in: controller.view)
            if screen == nil {
                // Not vacuous: the selected day's holiday is on screen, in English.
                XCTAssertTrue(texts.contains { $0.contains("National Day") }, "\(mode): \(texts)")
            }
            for text in texts where !endonyms.contains(text) {
                XCTAssertFalse(text.hasCJK, "\(mode)/\(String(describing: screen)): \"\(text)\"")
            }
        }
    }

    func testEnglishDefaultMenuBarTitleHasNoChinese() throws {
        Loc.language = .en
        let settings = englishSettings()
        let segments = StatusTitleProvider().segments(today: LocalDate(year: 2026, month: 9, day: 25), settings: settings)
        XCTAssertFalse(segments.isEmpty)
        for case let .text(text) in segments {
            XCTAssertFalse(text.hasCJK, "menu bar shows \(text)")
        }
    }

    /// VoiceOver reads accessibility descriptions verbatim; "chevron.left" is not a word.
    @MainActor func testIconControlsHaveSpokenNamesNotSymbolNames() throws {
        let symbolName = try NSRegularExpression(pattern: #"^[a-z]+(\.[a-z0-9]+)+$"#)
        for mode in ["luna", "sol"] {
            let controller = try englishController(mode: mode)
            for label in accessibilityText(in: controller.view) {
                let range = NSRange(label.startIndex..., in: label)
                XCTAssertNil(symbolName.firstMatch(in: label, range: range), "\(mode): accessibility label \"\(label)\"")
            }
        }
    }

    // MARK: Location pre-prompt (5.1.1(iv))

    func testLocationIsNotRequestedBeforeTheUserContinues() {
        let manager = RecordingLocationManager()
        let service = LocationService(store: DaylightStore(defaults: isolatedDefaults()), manager: manager)
        // CoreLocation fires this as soon as a delegate is attached.
        service.locationManagerDidChangeAuthorization(manager)
        XCTAssertEqual(manager.authorizationRequests, 0, "system prompt raised before Continue")
        service.start()
        XCTAssertEqual(manager.authorizationRequests, 1)
    }

    func testCachedLocationIsNotUsedUntilPermissionIsGranted() {
        let store = DaylightStore(defaults: isolatedDefaults())
        let cached = ObserverLocation(latitudeDegrees: 13.75, longitudeDegrees: 100.5)
        store.saveObserverLocation(cached)
        XCTAssertEqual(LocationService.resolution(for: .notDetermined, cachedLocation: cached), .needsPrompt)
        LocationService(store: store, manager: RecordingLocationManager()).start()
        XCTAssertNil(store.cachedObserverLocation(), "a coordinate from an earlier grant survived a reset")
    }

    @MainActor func testLocationPrePromptOffersOnlyContinue() {
        for language in AppLanguage.allCases {
            Loc.language = language
            let titles = buttonTitles(in: LocationPromptPanel(onAllow: {}))
            XCTAssertEqual(titles, [L("继续")], "[\(language)] \(titles)")
        }
    }

    // MARK: Holiday sources (2.1, 5.2.2)

    func testEveryHolidayPresetHasAWorkingFeed() {
        let ids = HolidayService.presets.map(\.id)
        XCTAssertEqual(ids, ["cn", "hk", "custom"], "tw had no feed; th's host forbids automated access")
        for preset in HolidayService.presets where preset.id != "custom" {
            for language in AppLanguage.allCases {
                let url = HolidayService.url(for: preset, language: language)
                XCTAssertEqual(url?.scheme, "https", "\(preset.id) [\(language)]")
            }
        }
    }

    func testHongKongFeedFollowsTheInterfaceLanguage() throws {
        let hk = try XCTUnwrap(HolidayService.preset("hk"))
        XCTAssertEqual(HolidayService.url(for: hk, language: .zh)?.lastPathComponent, "sc.ics")
        XCTAssertEqual(HolidayService.url(for: hk, language: .zhHant)?.lastPathComponent, "tc.ics")
        XCTAssertEqual(HolidayService.url(for: hk, language: .en)?.lastPathComponent, "en.ics")
        XCTAssertEqual(HolidayService.url(for: hk, language: .th)?.lastPathComponent, "en.ics")
    }

    func testRetiredPresetsMigrate() {
        let migrated = HolidayService.migratingRetiredPresets([
            HolidaySubscription(id: "a", sourceId: "tw", customURL: "", colorId: "rust", enabled: true),
            HolidaySubscription(id: "b", sourceId: "th", customURL: "", colorId: "olive", enabled: true),
            HolidaySubscription(id: "c", sourceId: "cn", customURL: "", colorId: "rust", enabled: true)
        ])
        XCTAssertEqual(migrated.map(\.id), ["b", "c"])
        XCTAssertEqual(migrated[0].sourceId, "custom")
        XCTAssertEqual(migrated[0].customURL, "https://www.officeholidays.com/ics/thailand")
        XCTAssertEqual(migrated[0].name, "泰国")
        XCTAssertEqual(migrated[0].colorId, "olive")
    }

    func testMainlandHolidayNamesAreTranslated() {
        let feed = """
        BEGIN:VCALENDAR
        BEGIN:VEVENT
        DTSTART;VALUE=DATE:20261001
        DTEND;VALUE=DATE:20261002
        SUMMARY:国庆节、中秋节
        END:VEVENT
        BEGIN:VEVENT
        DTSTART;VALUE=DATE:20261010
        DTEND;VALUE=DATE:20261011
        SUMMARY:国庆节（调休上班）
        X-DAYLIGHT-DAY-TYPE:WORKDAY
        END:VEVENT
        END:VCALENDAR
        """
        let feedNames = HolidayService.parse(ics: feed).compactMap(\.name)
        let allNames = feedNames + ["元旦", "春节", "清明节", "劳动节", "端午节", "中秋节", "国庆节"]
        for language in [AppLanguage.en, .th] {
            Loc.language = language
            for name in allNames {
                XCTAssertFalse(Loc.holidayName(name).hasCJK, "[\(language)] \(name) → \(Loc.holidayName(name))")
            }
        }
        Loc.language = .en
        XCTAssertEqual(Loc.holidayName("国庆节、中秋节"), "National Day / Mid-Autumn Festival")
    }

    func testHolidayRefreshFollowsTheChosenInterval() {
        let now = Date(timeIntervalSince1970: 1_790_000_000)
        let hoursAgo = { (hours: Double) in (date: now.addingTimeInterval(-hours * 3600), language: "en") }
        XCTAssertTrue(HolidayRefresher.isDue(lastSync: nil, language: "en", weekly: false, now: now))
        XCTAssertFalse(HolidayRefresher.isDue(lastSync: hoursAgo(23), language: "en", weekly: false, now: now))
        XCTAssertTrue(HolidayRefresher.isDue(lastSync: hoursAgo(24), language: "en", weekly: false, now: now))
        XCTAssertFalse(HolidayRefresher.isDue(lastSync: hoursAgo(24 * 6), language: "en", weekly: true, now: now))
        XCTAssertTrue(HolidayRefresher.isDue(lastSync: hoursAgo(24 * 7), language: "en", weekly: true, now: now))
        XCTAssertTrue(HolidayRefresher.isDue(lastSync: hoursAgo(1), language: "zh", weekly: false, now: now),
                      "a language change refetches feeds whose names are per language")
    }

    func testNoHolidaySubscriptionMeansNoNetwork() {
        let store = DaylightStore(defaults: isolatedDefaults())
        var changed = false
        HolidayRefresher(store: store).refreshIfDue { changed = true }
        XCTAssertNil(store.holidaySyncStamp())
        XCTAssertFalse(changed)
    }

    // MARK: Standard Mac behaviour (2.1, 4)

    func testMainMenuProvidesEditingShortcutsAndQuit() {
        let items = MainMenu.make().items.flatMap { $0.submenu?.items ?? [] }
        let shortcuts = Dictionary(items.compactMap { item in item.action.map { (NSStringFromSelector($0), item.keyEquivalent) } },
                                   uniquingKeysWith: { first, _ in first })
        let expected = ["terminate:": "q", "undo:": "z", "redo:": "Z", "cut:": "x", "copy:": "c", "paste:": "v", "selectAll:": "a"]
        for (action, key) in expected {
            XCTAssertEqual(shortcuts[action], key, action)
        }
    }

    func testMenuBarRefreshFiresOnTheMinute() {
        let date = Date(timeIntervalSinceReferenceDate: 60 * 1_000 + 42.5)
        XCTAssertEqual(AppDelegate.nextMinute(after: date).timeIntervalSinceReferenceDate, 60 * 1_001)
        let boundary = Date(timeIntervalSinceReferenceDate: 60 * 1_000)
        XCTAssertEqual(AppDelegate.nextMinute(after: boundary).timeIntervalSinceReferenceDate, 60 * 1_001)
    }

    // MARK: Settings (5.1.1(i), 2.1)

    func testPrivacyAndSupportLinksMatchTheStoreListing() throws {
        let listingURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("../../assets/store/mac-app-store/listing.json").standardized
        let listing = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: listingURL)) as? [String: Any])
        XCTAssertEqual(SiteLinks.privacyPolicy(.en).absoluteString, listing["privacyPolicyUrl"] as? String)
        XCTAssertEqual(SiteLinks.support(.en).absoluteString, listing["supportUrl"] as? String)
        XCTAssertEqual(SiteLinks.privacyPolicy(.zhHant).absoluteString, "https://daylight.mings.work/zh-hant/privacy")
    }

    @MainActor func testSettingsLinksThePrivacyPolicyAndKeepsQuitReachable() throws {
        Loc.language = .en
        let controller = try englishController(mode: "sol")
        let panel = CalendarSettingsPanel(
            store: controller.store, onDataChanged: {}, onNeedsRender: {}, onClose: {},
            onOpenStatusEditor: {}, onOpenHolidays: {}, onOpenSystemCalendar: {}, onToast: { _ in }
        )
        let titles = buttonTitles(in: panel).map { $0.trimmingCharacters(in: .whitespaces) }
        XCTAssertTrue(titles.contains { $0.hasPrefix(L("隐私政策")) }, "\(titles)")
        XCTAssertTrue(titles.contains { $0.hasPrefix(L("退出 Daylight")) }, "\(titles)")

        let natural = panel.fittingSize.height
        let cap = natural - 200
        let scroll = controller.scrollCapped(panel, maxHeight: cap)
        let host = NSView(frame: NSRect(x: 0, y: 0, width: Metrics.popoverWidth, height: 1000))
        host.addSubview(scroll)
        scroll.widthAnchor.constraint(equalToConstant: Metrics.popoverWidth).isActive = true
        host.layoutSubtreeIfNeeded()
        XCTAssertLessThanOrEqual(scroll.fittingSize.height, cap + 0.5, "settings must scroll on short displays")
        XCTAssertGreaterThan(Metrics.settingsMaxHeight(screen: nil), 0)
    }

    func testWeekStartControlReflectsEveryRule() {
        let panel = CalendarSettingsPanel(
            store: DaylightStore(defaults: isolatedDefaults()), onDataChanged: {}, onNeedsRender: {}, onClose: {},
            onOpenStatusEditor: {}, onOpenHolidays: {}, onOpenSystemCalendar: {}, onToast: { _ in }
        )
        XCTAssertEqual(panel.weekStartIndex(.iso8601), 0)
        XCTAssertEqual(panel.weekStartIndex(.us), 1)
        XCTAssertEqual(panel.weekStartIndex(.hebrew), 1)
        XCTAssertEqual(panel.weekStartIndex(.arabic), 2, "Saturday-first must not show as Monday")
    }

    // MARK: Helpers

    private func isolatedDefaults() -> UserDefaults {
        UserDefaults(suiteName: "daylight.review.\(UUID().uuidString)")!
    }

    private func englishSettings() -> UserSettings {
        var settings = UserSettings()
        let defaults = UserSettings.firstLaunch(language: .en, locale: Locale(identifier: "en_US"))
        settings.language = AppLanguage.en.rawValue
        settings.showLunarDate = defaults.showLunarDate
        settings.statusSegments = defaults.statusSegments
        settings.statusUse24HourTime = defaults.use24Hour
        settings.calendarType = defaults.weekRule.rawValue
        settings.systemCalendarEnabled = false
        return settings
    }

    /// An English user on first launch who subscribed to mainland holidays
    /// (Chinese names in the feed), looking at National Day.
    @MainActor private func englishController(mode: String) throws -> PopoverViewController {
        let store = DaylightStore(defaults: isolatedDefaults())
        var settings = englishSettings()
        settings.uiMode = mode
        let subscription = HolidaySubscription(id: "review-cn", sourceId: "cn", customURL: "", colorId: "rust", enabled: true)
        settings.holidaySubscriptions = [subscription]
        store.saveSettings(settings)
        store.replaceHolidayDays([
            PublicCalendarDay(date: "2026-10-01", type: "holiday", name: "国庆节、中秋节", isImportant: true),
            PublicCalendarDay(date: "2026-10-02", type: "holiday", name: "国庆节", isImportant: true),
            PublicCalendarDay(date: "2026-10-10", type: "workday", name: "国庆节", isImportant: true)
        ], for: subscription.id)
        let controller = PopoverViewController(store: store, calendarModel: CalendarModel(), onDataChanged: {})
        controller.selectedDate = LocalDate(year: 2026, month: 10, day: 1)
        controller.visibleMonth = LocalDate(year: 2026, month: 10, day: 1)
        _ = controller.view
        controller.render()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        return controller
    }

    private func visibleText(in view: NSView) -> [String] {
        var texts: [String] = []
        if !view.isHidden {
            if let field = view as? NSTextField, !field.stringValue.isEmpty { texts.append(field.stringValue) }
            if let tip = view.toolTip, !tip.isEmpty { texts.append(tip) }
            texts += accessibilityText(in: view, recursive: false)
            texts += view.subviews.flatMap(visibleText(in:))
        }
        return texts
    }

    private func accessibilityText(in view: NSView, recursive: Bool = true) -> [String] {
        var texts: [String] = []
        if let label = view.accessibilityLabel(), !label.isEmpty { texts.append(label) }
        if let image = (view as? NSImageView)?.image?.accessibilityDescription, !image.isEmpty { texts.append(image) }
        if recursive { texts += view.subviews.flatMap { accessibilityText(in: $0) } }
        return texts
    }

    private func buttons(in view: NSView) -> [RowButton] {
        (view as? RowButton).map { [$0] } ?? view.subviews.flatMap(buttons(in:))
    }

    private func text(in view: NSView) -> String {
        if let field = view as? NSTextField { return field.stringValue }
        return view.subviews.map(text(in:)).joined()
    }

    private func buttonTitles(in view: NSView) -> [String] { buttons(in: view).map(text(in:)) }
}

/// Records authorization requests instead of raising the system dialog.
private final class RecordingLocationManager: CLLocationManager {
    var authorizationRequests = 0
    override var authorizationStatus: CLAuthorizationStatus { .notDetermined }
    override func requestWhenInUseAuthorization() { authorizationRequests += 1 }
}

private extension String {
    var hasCJK: Bool { unicodeScalars.contains { (0x3400...0x9FFF).contains($0.value) } }
}
