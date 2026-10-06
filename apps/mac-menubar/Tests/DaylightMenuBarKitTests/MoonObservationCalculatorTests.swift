// XCTest coverage for location-based moon observation calculations.
// Exports: MoonObservationCalculatorTests
// Deps: XCTest, DaylightMenuBarKit, Foundation Date

import Foundation
import XCTest
@testable import DaylightMenuBarKit

final class MoonObservationCalculatorTests: XCTestCase {
    func testObservationValuesStayInPhysicalRanges() {
        let calculator = MoonObservationCalculator()
        let location = ObserverLocation(latitudeDegrees: 37.7749, longitudeDegrees: -122.4194)

        let observation = calculator.observation(
            at: date(year: 2026, month: 6, day: 29, hour: 12),
            location: location
        )

        XCTAssertEqual(observation.location, location)
        XCTAssertGreaterThanOrEqual(observation.illuminatedFraction, 0)
        XCTAssertLessThanOrEqual(observation.illuminatedFraction, 1)
        XCTAssertGreaterThanOrEqual(observation.ageDays, 0)
        XCTAssertLessThan(observation.ageDays, 29.6)
        XCTAssertGreaterThanOrEqual(observation.altitudeDegrees, -90)
        XCTAssertLessThanOrEqual(observation.altitudeDegrees, 90)
        XCTAssertGreaterThanOrEqual(observation.azimuthDegrees, 0)
        XCTAssertLessThan(observation.azimuthDegrees, 360)
    }

    /// 2026-09-11 03:27 UTC is a new moon (USNO). The J2000/Schlyter epoch
    /// mix-up reported it as a 28-day-old waning crescent.
    func testKnownNewMoonIsNew() {
        let observation = MoonObservationCalculator().observation(
            at: Date(timeIntervalSince1970: 1_789_097_220),
            location: ObserverLocation(latitudeDegrees: 0, longitudeDegrees: 0)
        )
        XCTAssertTrue(observation.ageDays < 1 || observation.ageDays > 28.5, "age \(observation.ageDays)")
        XCTAssertLessThan(observation.illuminatedFraction, 0.02)
    }

    /// The popover's moon must agree with the menu bar icon (Meeus series).
    func testIlluminationAgreesWithMenuBarMoonPhase() {
        let calculator = MoonObservationCalculator()
        let menuBar = MoonPhaseCalculator()
        let location = ObserverLocation(latitudeDegrees: 0, longitudeDegrees: 0)
        let start = date(year: 2026, month: 1, day: 1, hour: 0)
        for step in 0..<120 {
            let instant = start.addingTimeInterval(Double(step) * 3 * 86_400)
            let popover = calculator.observation(at: instant, location: location).illuminatedFraction
            XCTAssertEqual(popover, menuBar.illuminatedFraction(for: instant), accuracy: 0.04, "\(instant)")
        }
    }

    func testKnownFullMoonDateIsMostlyIlluminated() {
        let calculator = MoonObservationCalculator()
        let location = ObserverLocation(latitudeDegrees: 0, longitudeDegrees: 0)

        let observation = calculator.observation(
            at: date(year: 2000, month: 1, day: 21, hour: 4),
            location: location
        )

        XCTAssertEqual(observation.phaseName, "Full Moon")
        XCTAssertGreaterThan(observation.illuminatedFraction, 0.9)
    }

    func testMoonObservationDateResolverUsesNoonForNonTodayDate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let calculator = MoonObservationCalculator()
        let location = ObserverLocation(latitudeDegrees: 0, longitudeDegrees: 0)
        let now = date(year: 2026, month: 7, day: 17, hour: 9)
        let displayDate = LocalDate(year: 2026, month: 7, day: 23)

        let resolved = MoonObservationDateResolver.observationDate(
            for: displayDate,
            now: now,
            calendar: calendar
        )
        let expectedNoon = date(year: 2026, month: 7, day: 23, hour: 12)
        let selectedObservation = calculator.observation(at: resolved, location: location)
        let expectedObservation = calculator.observation(at: expectedNoon, location: location)
        let todayObservation = calculator.observation(at: now, location: location)

        XCTAssertEqual(resolved, expectedNoon)
        XCTAssertEqual(selectedObservation.illuminatedFraction, expectedObservation.illuminatedFraction, accuracy: 0.000000000001)
        XCTAssertEqual(selectedObservation.ageDays, expectedObservation.ageDays, accuracy: 0.000000000001)
        XCTAssertGreaterThan(abs(selectedObservation.ageDays - todayObservation.ageDays), 0.1)
    }

    func testMoonObservationDateResolverKeepsTodayAtCurrentInstant() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = date(year: 2026, month: 7, day: 17, hour: 9)
        let today = LocalDate(year: 2026, month: 7, day: 17)

        let resolved = MoonObservationDateResolver.observationDate(
            for: today,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(resolved, now)
    }

    private func date(year: Int, month: Int, day: Int, hour: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: day,
            hour: hour
        ))!
    }
}
