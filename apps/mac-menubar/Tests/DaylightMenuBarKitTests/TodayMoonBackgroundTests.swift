import AppKit
import XCTest
@testable import DaylightMenuBarKit

@MainActor
final class TodayMoonBackgroundTests: XCTestCase {
    func testTodayUsesTheSamePhaseAsTheDateDetail() throws {
        for day in [1, 5, 11, 15, 18, 23, 26] {
            let date = LocalDate(year: 2026, month: 9, day: day)
            let cell = makeCell(date: date, today: true, subtitle: true)
            let backdrop = try XCTUnwrap(cell.subviews.compactMap { $0 as? TodayMoonBackgroundView }.first)
            let moon = MoonObservationCalculator().observation(
                at: date.noonDate, location: ObserverLocation(latitudeDegrees: 0, longitudeDegrees: 0)
            )
            XCTAssertEqual(backdrop.fraction, moon.illuminatedFraction, accuracy: 0.0001)
            XCTAssertEqual(backdrop.waxing, moon.phaseAngleDegrees < 180)
            XCTAssertNil(backdrop.hitTest(.zero))
            let ordinary = makeCell(date: date, today: false, subtitle: true)
            XCTAssertFalse(ordinary.subviews.contains { $0 is TodayMoonBackgroundView })
        }
        try exportPreview()
    }

    func testTextContrastOnBothMoonHalvesInBothAppearances() {
        for name in [NSAppearance.Name.aqua, .darkAqua] {
            NSAppearance(named: name)!.performAsCurrentDrawingAppearance {
                let text = luminance(Palette.todayMoonInk)
                for background in [Palette.todayMoonLit, Palette.todayMoonShadow] {
                    let fill = luminance(background)
                    let ratio = (max(text, fill) + 0.05) / (min(text, fill) + 0.05)
                    XCTAssertGreaterThanOrEqual(ratio, 4.5, "Small date text must remain readable on either half")
                }
                XCTAssertGreaterThan(luminance(Palette.todayMoonLit), luminance(Palette.todayMoonShadow))
            }
        }
    }

    private func luminance(_ color: NSColor) -> Double {
        let rgb = color.usingColorSpace(.sRGB)!
        func linear(_ value: CGFloat) -> Double {
            let v = Double(value)
            return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(rgb.redComponent) + 0.7152 * linear(rgb.greenComponent) + 0.0722 * linear(rgb.blueComponent)
    }

    private func makeCell(date: LocalDate, today: Bool, subtitle: Bool) -> LunaDateCell {
        LunaDateCell(
            day: CalendarDay(date: date, isToday: today, isOutsideMonth: false),
            title: CalendarDayTitle(primary: String(date.day), secondary: subtitle ? "十三" : nil,
                                    isSolarTerm: false, holidayColorIds: ["rust", "green"]),
            events: [], selectedDate: date, showsSubtitle: subtitle, onSelectDate: { _ in }
        )
    }

    private func exportPreview() throws {
        guard let directory = ProcessInfo.processInfo.environment["DAYLIGHT_MOON_PREVIEW_DIR"] else { return }
        for (label, appearance) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
            let sheet = UI.roundedBox(fill: Palette.surface, radius: 0)
            sheet.appearance = NSAppearance(named: appearance)
            sheet.frame = NSRect(x: 0, y: 0, width: 420, height: 160)
            NSLayoutConstraint.activate([
                sheet.widthAnchor.constraint(equalToConstant: 420),
                sheet.heightAnchor.constraint(equalToConstant: 160)
            ])
            for (index, day) in [1, 5, 11, 15, 18, 23, 26].enumerated() {
                for (row, subtitle) in [false, true].enumerated() {
                    let cell = makeCell(date: LocalDate(year: 2026, month: 9, day: day), today: true, subtitle: subtitle)
                    sheet.addSubview(cell)
                    NSLayoutConstraint.activate([
                        cell.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: CGFloat(index * 58 + 7)),
                        cell.topAnchor.constraint(equalTo: sheet.topAnchor, constant: CGFloat(row * 70 + 18)),
                        cell.widthAnchor.constraint(equalToConstant: 44)
                    ])
                }
            }
            sheet.layoutSubtreeIfNeeded()
            let rep = try XCTUnwrap(sheet.bitmapImageRepForCachingDisplay(in: sheet.bounds))
            sheet.cacheDisplay(in: sheet.bounds, to: rep)
            let data = try XCTUnwrap(rep.representation(using: .png, properties: [:]))
            try data.write(to: URL(fileURLWithPath: directory).appendingPathComponent("today-moon-\(label).png"))
        }
    }
}
