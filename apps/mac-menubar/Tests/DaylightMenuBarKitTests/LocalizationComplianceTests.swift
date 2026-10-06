import AppKit
import XCTest
@testable import DaylightMenuBarKit

/// App Review guards. 2.0.5 was rejected under Guideline 4 (the system permission
/// prompts were Chinese-only while the app showed English) and 5.1.1(iv) (the
/// screen before the calendar prompt said "Authorize calendar access" instead of
/// "Continue"). These tests keep both classes of problem from coming back.
final class LocalizationComplianceTests: XCTestCase {
    // MARK: System permission prompts (Info.plist)

    /// The .lproj each in-app language resolves to for system-rendered strings.
    private static let lprojByLanguage: [AppLanguage: String] = [
        .zh: "zh-Hans", .zhHant: "zh-Hant", .en: "en", .th: "th"
    ]

    func testEveryAppLanguageShipsEveryPermissionString() throws {
        let usageKeys = Set(try infoPlistTemplate().keys.filter { $0.hasSuffix("UsageDescription") })
        XCTAssertFalse(usageKeys.isEmpty)
        for language in AppLanguage.allCases {
            let lproj = try XCTUnwrap(Self.lprojByLanguage[language], "no .lproj mapped for \(language)")
            let strings = try permissionStrings(lproj)
            XCTAssertEqual(Set(strings.keys), usageKeys, "\(lproj).lproj must translate exactly the Info.plist usage keys")
            for (key, value) in strings {
                XCTAssertFalse(value.trimmingCharacters(in: .whitespaces).isEmpty, "\(lproj): \(key) is empty")
            }
        }
    }

    func testPermissionStringsAreWrittenInTheirOwnLanguage() throws {
        // The base Info.plist is the fallback for unsupported system languages,
        // which the app itself shows in English.
        for (key, value) in try infoPlistTemplate() where key.hasSuffix("UsageDescription") {
            let text = try XCTUnwrap(value as? String)
            XCTAssertFalse(text.hasCJK || text.hasThai, "Info.plist \(key) must be English: \(text)")
        }
        for (key, text) in try permissionStrings("en") {
            XCTAssertFalse(text.hasCJK || text.hasThai, "en: \(key) must be English: \(text)")
        }
        let simplified = try permissionStrings("zh-Hans")
        let traditional = try permissionStrings("zh-Hant")
        for (key, text) in simplified {
            XCTAssertTrue(text.hasCJK, "zh-Hans: \(key) is not Chinese: \(text)")
            XCTAssertNotEqual(traditional[key], text, "zh-Hant: \(key) is a copy of the Simplified text")
        }
        for (key, text) in traditional {
            XCTAssertTrue(text.hasCJK, "zh-Hant: \(key) is not Chinese: \(text)")
            XCTAssertEqual(text.icuTraditional, text, "zh-Hant: \(key) still has Simplified characters")
        }
        for (key, text) in try permissionStrings("th") {
            XCTAssertTrue(text.hasThai, "th: \(key) is not Thai: \(text)")
            XCTAssertFalse(text.hasCJK, "th: \(key) contains Chinese: \(text)")
        }
    }

    /// A protected API used without its usage string crashes or is rejected.
    func testEveryProtectedAPIHasAUsageDescription() throws {
        let required: [(token: String, keys: [String])] = [
            ("EKEventStore", ["NSCalendarsUsageDescription", "NSCalendarsFullAccessUsageDescription"]),
            ("to: .reminder", ["NSRemindersUsageDescription", "NSRemindersFullAccessUsageDescription"]),
            ("requestFullAccessToReminders", ["NSRemindersUsageDescription", "NSRemindersFullAccessUsageDescription"]),
            ("CLLocationManager", ["NSLocationUsageDescription", "NSLocationWhenInUseUsageDescription"]),
            ("CNContactStore", ["NSContactsUsageDescription"]),
            ("AVCaptureDevice", ["NSCameraUsageDescription", "NSMicrophoneUsageDescription"]),
            ("PHPhotoLibrary", ["NSPhotoLibraryUsageDescription"]),
            ("SFSpeechRecognizer", ["NSSpeechRecognitionUsageDescription"])
        ]
        let source = try sourceFiles().map { try String(contentsOf: $0, encoding: .utf8) }.joined(separator: "\n")
        let keys = Set(try infoPlistTemplate().keys)
        for entry in required where source.contains(entry.token) {
            for key in entry.keys {
                XCTAssertTrue(keys.contains(key), "Sources use \(entry.token) but Info.plist lacks \(key)")
            }
        }
    }

    func testPackagingShipsTheLocalizedPermissionStrings() throws {
        XCTAssertEqual(try infoPlistTemplate()["CFBundleDevelopmentRegion"] as? String, "en")
        XCTAssertEqual(try infoPlistTemplate()["CFBundleInfoDictionaryVersion"] as? String, "6.0")
        for script in ["scripts/install-local.sh", "scripts/package-app-store.sh"] {
            let text = try String(contentsOf: packageRoot.appendingPathComponent(script), encoding: .utf8)
            XCTAssertTrue(text.contains(#"packaging/Localizations/"*.lproj"#), "\(script) does not copy the .lproj folders")
        }
        // The direct release re-homes the install-local bundle, so it inherits them.
        let release = try String(contentsOf: packageRoot.appendingPathComponent("scripts/release-macos.sh"), encoding: .utf8)
        XCTAssertTrue(release.contains(".build/local/DaylightMenuBar.app"))
    }

    // MARK: Pre-permission screens (5.1.1(iv))

    /// The control that leads into a system permission dialog must read
    /// "Continue", never "Allow" / "Authorize" / "授权".
    @MainActor func testPrePermissionButtonsSayContinue() throws {
        try forEachLanguage { language in
            let screens: [(String, NSView, String)] = [
                ("Luna agenda", eventList(.notDetermined), "requestAccess"),
                ("Sol calendar settings", try calendarPanel().authorizationCard(canRequestAccess: true), "requestAccess"),
                ("3D moon location", LocationPromptPanel(onAllow: {}), "allow")
            ]
            for (name, view, action) in screens {
                let title = try XCTUnwrap(buttonTitle(in: view, action: action), "\(name): no \(action) button")
                XCTAssertEqual(title, L("继续"), "\(name) [\(language)]: pre-permission button reads \"\(title)\"")
            }
        }
    }

    /// Once the dialog was answered the button only opens System Settings.
    @MainActor func testDeniedCalendarStateLinksToSystemSettings() throws {
        try forEachLanguage { language in
            for (name, view) in [("Luna agenda", eventList(.denied)),
                                 ("Sol calendar settings", try calendarPanel().authorizationCard(canRequestAccess: false))] {
                let titles = buttonTitles(in: view)
                XCTAssertTrue(titles.contains(L("打开系统设置")), "\(name) [\(language)]: \(titles)")
            }
        }
    }

    // MARK: In-app strings

    func testEveryLiteralLocalizationKeyIsTranslated() throws {
        for (file, line, key) in try literals(matching: #"\bL\("((?:[^"\\]|\\.)*)"\)"#) where !key.contains(#"\("#) {
            let entry = Loc.table[key]
            XCTAssertNotNil(entry?[.en], "\(file):\(line) L(\"\(key)\") has no English translation")
            XCTAssertNotNil(entry?[.th], "\(file):\(line) L(\"\(key)\") has no Thai translation")
        }
    }

    func testTranslationsAreWrittenInTheirOwnLanguage() {
        let thaiProperNames: Set<String> = ["ISO 8601", "officeholidays.com", "Daylight"]
        for (key, entry) in Loc.table {
            if let en = entry[.en] {
                XCTAssertFalse(en.hasCJK || en.hasThai, "en for \(key) is not English: \(en)")
            }
            if let th = entry[.th] {
                XCTAssertFalse(th.hasCJK, "th for \(key) contains Chinese: \(th)")
                XCTAssertTrue(th.hasThai || thaiProperNames.contains(th), "th for \(key) is not Thai: \(th)")
            }
        }
    }

    /// Traditional Chinese is converted from the Simplified keys by a generated
    /// character map; a character missing from it shows Simplified in the 繁 UI
    /// (继续 did). ICU's Hans-Hant transform is the oracle for "nothing left".
    func testTraditionalChineseLeavesNoSimplifiedCharacters() throws {
        let literalKeys = try literals(matching: #"\bL\("((?:[^"\\]|\\.)*)"\)"#).map(\.2).filter { !$0.contains(#"\("#) }
        for key in Set(Loc.table.keys).union(literalKeys) {
            let converted = TraditionalChinese.convert(key)
            XCTAssertEqual(converted.icuTraditional, converted, "繁 UI shows Simplified for \(key): \(converted)")
        }
    }

    /// Chinese text in code must be a table key (so L() can translate it, even
    /// when passed indirectly) or one of the documented Chinese-only cases.
    func testHardcodedChineseGoesThroughTheTable() throws {
        // Lunar calendar and solar-term data stay Chinese by design
        // (docs/mac-menubar-progress.md, "Lunar text stays Chinese").
        let chineseDataFiles: Set<String> = ["LunarCalendar.swift", "SolarTermIconGlyphs.swift", "SolarTermIconView.swift"]
        let chineseOnly: Set<String> = [
            "班",                                         // workday badge, zh branch only ("W" otherwise)
            "（调休上班）",                                 // suffix parsed out of the CN holiday feed
            #"\(value) 天 / 年"#, #"\(value) 天"#,          // HolidaySourceCountFormatter zh branch
            "年", "月", "日",                               // EventListPanel.longDate zh branch
            #" · \(lunar.monthName)月\(lunar.dayName)"#,    // lunar suffix
            #"\(lunar.yearName)年 · \(lunar.monthName)月"#   // lunar header subtitle
        ]
        for (file, line, literal) in try literals(matching: #""((?:[^"\\]|\\.)*)""#, stripping: #"\bL\("(?:[^"\\]|\\.)*"\)"#)
        where literal.hasCJK && !chineseDataFiles.contains(file) {
            XCTAssertTrue(Loc.table[literal] != nil || chineseOnly.contains(literal),
                          "\(file):\(line) hardcodes \"\(literal)\" outside L() and the translation table")
        }
    }

    /// An unpinned DateFormatter follows the system calendar and locale, so a
    /// Buddhist or Japanese system calendar rewrites years behind the app's
    /// language setting.
    func testDateFormattersPinTheirLocale() throws {
        for url in try sourceFiles() {
            let lines = try String(contentsOf: url, encoding: .utf8).components(separatedBy: "\n")
            for (index, line) in lines.enumerated() where line.range(of: #"\bDateFormatter\(\)"#, options: .regularExpression) != nil {
                let setup = lines[index..<min(index + 8, lines.count)].joined(separator: "\n")
                XCTAssertTrue(setup.contains(".locale ="), "\(url.lastPathComponent):\(index + 1) DateFormatter without a pinned locale")
            }
        }
    }

    // MARK: Helpers

    private var packageRoot: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }

    private func sourceFiles() throws -> [URL] {
        let root = packageRoot.appendingPathComponent("Sources/DaylightMenuBar")
        let files = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)!
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "swift" && !["Localization.swift", "TraditionalChinese.swift"].contains($0.lastPathComponent) }
        XCTAssertFalse(files.isEmpty)
        return files
    }

    /// The Info.plist written by install-local.sh, which package-app-store.sh reuses.
    private func infoPlistTemplate() throws -> [String: Any] {
        let script = try String(contentsOf: packageRoot.appendingPathComponent("scripts/install-local.sh"), encoding: .utf8)
        let body = try XCTUnwrap(script.range(of: #"(?s)<<'PLIST'\n(.*?)\nPLIST"#, options: .regularExpression).map { script[$0] })
        let xml = body.dropFirst("<<'PLIST'\n".count).dropLast("\nPLIST".count)
        let plist = try PropertyListSerialization.propertyList(from: Data(xml.utf8), format: nil)
        return try XCTUnwrap(plist as? [String: Any])
    }

    private func permissionStrings(_ lproj: String) throws -> [String: String] {
        let url = packageRoot.appendingPathComponent("packaging/Localizations/\(lproj).lproj/InfoPlist.strings")
        return try XCTUnwrap(NSDictionary(contentsOf: url) as? [String: String], "missing or unparsable \(lproj).lproj/InfoPlist.strings")
    }

    /// String literals in Sources (comments skipped), optionally after removing `stripping` matches.
    private func literals(matching pattern: String, stripping: String? = nil) throws -> [(String, Int, String)] {
        let regex = try NSRegularExpression(pattern: pattern)
        var found: [(String, Int, String)] = []
        for url in try sourceFiles() {
            for (index, rawLine) in try String(contentsOf: url, encoding: .utf8).components(separatedBy: "\n").enumerated() {
                guard !rawLine.trimmingCharacters(in: .whitespaces).hasPrefix("//") else { continue }
                var line = rawLine.components(separatedBy: " // ")[0]
                if let stripping { line = line.replacingOccurrences(of: stripping, with: "", options: .regularExpression) }
                for match in regex.matches(in: line, range: NSRange(line.startIndex..., in: line)) {
                    guard let range = Range(match.range(at: 1), in: line) else { continue }
                    found.append((url.lastPathComponent, index + 1, String(line[range])))
                }
            }
        }
        return found
    }

    private func forEachLanguage(_ body: (AppLanguage) throws -> Void) rethrows {
        let previous = Loc.language
        defer { Loc.language = previous }
        for language in AppLanguage.allCases {
            Loc.language = language
            try body(language)
        }
    }

    @MainActor private func eventList(_ authorization: SystemCalendarAuthorization) -> EventListPanel {
        EventListPanel(
            selectedDate: LocalDate(year: 2026, month: 10, day: 4), holidays: [], events: [],
            authorization: authorization, showLunarDate: false,
            onOpenEvent: { _ in }, onOpenMoon: { _ in }, onRequestAccess: {}
        )
    }

    @MainActor private func calendarPanel() throws -> SystemCalendarPanel {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "daylight.compliance.\(UUID().uuidString)"))
        let store = DaylightStore(defaults: defaults)
        var settings = store.settings()
        settings.systemCalendarEnabled = false // keep render() away from EventKit
        store.saveSettings(settings)
        return SystemCalendarPanel(store: store, onDataChanged: {}, onNeedsRender: {}, onClose: {})
    }

    private func buttons(in view: NSView) -> [RowButton] {
        (view as? RowButton).map { [$0] } ?? view.subviews.flatMap(buttons(in:))
    }

    private func text(in view: NSView) -> String {
        if let field = view as? NSTextField { return field.stringValue }
        return view.subviews.map(text(in:)).joined()
    }

    private func buttonTitles(in view: NSView) -> [String] { buttons(in: view).map(text(in:)) }

    private func buttonTitle(in view: NSView, action: String) -> String? {
        buttons(in: view).first { $0.action.map(NSStringFromSelector) == action }.map(text(in:))
    }
}

private extension StringProtocol {
    var hasCJK: Bool { unicodeScalars.contains { (0x3400...0x9FFF).contains($0.value) } }
    var hasThai: Bool { unicodeScalars.contains { (0x0E00...0x0E7F).contains($0.value) } }
    var icuTraditional: String {
        String(self).applyingTransform(StringTransform("Hans-Hant"), reverse: false) ?? String(self)
    }
}
