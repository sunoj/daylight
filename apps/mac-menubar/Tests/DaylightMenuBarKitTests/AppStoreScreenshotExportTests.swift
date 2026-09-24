// Optional release artwork export using actual AppKit calendar views and demo data.
import AppKit
import XCTest
@testable import DaylightMenuBarKit

@MainActor
final class AppStoreScreenshotExportTests: XCTestCase {
    func testExportStoreScreenshots() throws {
        guard let directory = ProcessInfo.processInfo.environment["DAYLIGHT_STORE_SCREENSHOTS"] else {
            throw XCTSkip("Set DAYLIGHT_STORE_SCREENSHOTS to export release screenshots")
        }
        let previousLanguage = Loc.language
        defer { Loc.language = previousLanguage }
        if let siteDirectory = ProcessInfo.processInfo.environment["DAYLIGHT_SITE_SCREENSHOTS"] {
            let output = URL(fileURLWithPath: siteDirectory)
            try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
            let moon = MoonArt.statusImage(fraction: 0.92, waxing: true, pointSize: 32)
            let moonData = try XCTUnwrap(moon.tiffRepresentation)
            let moonBitmap = try XCTUnwrap(NSBitmapImageRep(data: moonData))
            try XCTUnwrap(moonBitmap.representation(using: .png, properties: [:]))
                .write(to: output.appendingPathComponent("status-moon.png"))
        }
        for (locale, language) in [("en-US", "en"), ("zh-Hans", "zh"), ("zh-Hant", "zh-Hant"), ("th", "th")] {
            for (index, mode, lunar, dark) in [(1, "luna", true, false), (2, "luna", true, true), (3, "sol", true, false)] {
                let suite = "daylight.store-preview.\(UUID().uuidString)"
                let defaults = UserDefaults(suiteName: suite)!
                defer { defaults.removePersistentDomain(forName: suite) }
                let store = DaylightStore(defaults: defaults)
                var settings = store.settings()
                settings.uiMode = mode
                settings.language = language
                settings.colorScheme = dark ? "dark" : "light"
                settings.showLunarDate = lunar
                settings.lunaShowLunarDate = lunar
                settings.systemCalendarEnabled = false
                let holidaySubscription = HolidaySubscription(id: "screenshot-cn", sourceId: "cn", customURL: "", colorId: "rust", enabled: true)
                settings.holidaySubscriptions = [holidaySubscription]
                store.saveSettings(settings)
                store.replaceHolidayDays(Self.autumnHolidays, for: holidaySubscription.id)
                let date = LocalDate(year: 2026, month: 9, day: 23)
                let demoNote = language == "en" ? "Take a walk after lunch" : language == "th" ? "เดินเล่นหลังอาหารกลางวัน" : language == "zh-Hant" ? "午飯後散步" : "午饭后散步"
                store.addThought(for: date, content: demoNote, done: false)
                let controller = PopoverViewController(store: store, calendarModel: CalendarModel(), onDataChanged: {})
                controller.selectedDate = date
                controller.visibleMonth = LocalDate(year: 2026, month: 9, day: 1)
                let root = controller.view
                RunLoop.main.run(until: Date().addingTimeInterval(0.15))
                let width = mode == "luna" ? Metrics.lunaPopoverWidth : Metrics.popoverWidth
                let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: width, height: 600),
                                      styleMask: .borderless, backing: .buffered, defer: false)
                window.contentView = root
                window.setContentSize(NSSize(width: width, height: root.fittingSize.height))
                window.layoutIfNeeded()
                root.layoutSubtreeIfNeeded()
                XCTAssertEqual(controller.rootStack.frame.width, root.bounds.width, accuracy: 0.5)
                let rep = try XCTUnwrap(root.bitmapImageRepForCachingDisplay(in: root.bounds))
                root.cacheDisplay(in: root.bounds, to: rep)
                if index == 1, let siteDirectory = ProcessInfo.processInfo.environment["DAYLIGHT_SITE_SCREENSHOTS"] {
                    let output = URL(fileURLWithPath: siteDirectory)
                    try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
                    try XCTUnwrap(rep.representation(using: .png, properties: [:]))
                        .write(to: output.appendingPathComponent("calendar-\(language == "zh-Hant" ? "zh-hant" : language).png"))
                }
                if language == "th" || language == "zh-Hant" { continue }
                let screenshot = NSImage(size: root.bounds.size)
                screenshot.addRepresentation(rep)
                let englishTitles = ["A little calendar.\nA clearer day.", "Your day,\nat a glance.", "Follow the seasons.\nKeep your thoughts."]
                let chineseTitles = ["小小日历，\n让每一天更清晰。", "今天的安排，\n一眼就知道。", "跟随四季，\n记录日常。"]
                let subtitles = language == "en"
                    ? ["Lunar dates, solar terms and the moon — right in your menu bar.", "A compact calendar with a quiet dark appearance and a diary for your day.", "Switch between Luna and Sol, explore dates and keep a daily note."]
                    : ["农历、节气和月相，\n在菜单栏里轻松查看。", "简洁日历、舒适深色外观，\n还有属于每一天的日记。", "Luna 与 Sol 两种界面，\n查看日期，记录生活。"]
                let output = URL(fileURLWithPath: directory).appendingPathComponent(locale)
                try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
                try compose(screenshot: screenshot, title: (language == "en" ? englishTitles : chineseTitles)[index - 1],
                            subtitle: subtitles[index - 1], dark: dark,
                            url: output.appendingPathComponent("0\(index)-\(mode).png"))
            }
        }
    }

    // September/October 2026 dates verified against the published China feed.
    // Keep screenshot export deterministic and independent of network access.
    private static var autumnHolidays: [PublicCalendarDay] {
        let midAutumn = (25...27).map {
            PublicCalendarDay(date: "2026-09-\($0)", type: "holiday", name: "中秋节", isImportant: true)
        }
        let nationalDay = (1...7).map {
            PublicCalendarDay(date: "2026-10-0\($0)", type: "holiday", name: "国庆节", isImportant: true)
        }
        let workdays = ["2026-09-20", "2026-10-10"].map {
            PublicCalendarDay(date: $0, type: "workday", name: "国庆节", isImportant: true)
        }
        return midAutumn + nationalDay + workdays
    }

    private func compose(screenshot: NSImage, title: String, subtitle: String, dark: Bool, url: URL) throws {
        let context = try XCTUnwrap(CGContext(data: nil, width: 1280, height: 800, bitsPerComponent: 8,
                                              bytesPerRow: 1280 * 4, space: CGColorSpaceCreateDeviceRGB(),
                                              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        defer { NSGraphicsContext.restoreGraphicsState() }
        (dark ? Palette.rgb(0x171916) : Palette.rgb(0xF6F5F0)).setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 1280, height: 800)).fill()
        let ink = dark ? Palette.rgb(0xECEBE7) : Palette.rgb(0x262C22)
        let secondary = dark ? Palette.rgb(0xB5BCAD) : Palette.rgb(0x68725F)
        ("DAYLIGHT" as NSString).draw(at: NSPoint(x: 80, y: 650), withAttributes: [.font: NSFont.systemFont(ofSize: 17, weight: .semibold), .foregroundColor: secondary, .kern: 3])
        (title as NSString).draw(in: NSRect(x: 80, y: 365, width: 530, height: 225), withAttributes: [.font: NSFont.systemFont(ofSize: 47, weight: .semibold), .foregroundColor: ink])
        (subtitle as NSString).draw(in: NSRect(x: 80, y: 225, width: 455, height: 110), withAttributes: [.font: NSFont.systemFont(ofSize: 23), .foregroundColor: secondary])
        let scale = min(1.35, 640 / screenshot.size.height, 520 / screenshot.size.width)
        let size = NSSize(width: screenshot.size.width * scale, height: screenshot.size.height * scale)
        let rect = NSRect(x: 640 + (560 - size.width) / 2, y: (800 - size.height) / 2, width: size.width, height: size.height)
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect: rect, xRadius: 18, yRadius: 18).addClip()
        screenshot.draw(in: rect)
        NSGraphicsContext.restoreGraphicsState()
        let bitmap = NSBitmapImageRep(cgImage: try XCTUnwrap(context.makeImage()))
        try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: url)
    }
}
