// Moon phase calculation for menu bar status rendering.
// Exports: MoonPhaseCalculator
// Deps: Foundation Date

import Foundation

final class MoonPhaseCalculator {
    private let j2000 = Date(timeIntervalSince1970: 946_728_000) // 2000-01-01 12:00 UTC

    /// Illuminated fraction 0…1 for the given date.
    func illuminatedFraction(for date: Date) -> Double {
        (1 - cos(2 * .pi * phaseValue(for: date))) / 2
    }

    /// True while the moon is waxing (new → full).
    func isWaxing(for date: Date) -> Bool {
        phaseValue(for: date) < 0.5
    }

    /// Phase 0…1 (0 = new, 0.5 = full) from the true sun–moon elongation,
    /// using the truncated series from Meeus, "Astronomical Algorithms"
    /// (~0.3° ≈ 35 minutes of phase). Mirrors getMoonPhase in core-calendar;
    /// the previous mean-phase approximation drifted up to ±1 day.
    private func phaseValue(for date: Date) -> Double {
        let d = date.timeIntervalSince(j2000) / 86_400
        let rad = Double.pi / 180
        let sunAnomaly = (357.529 + 0.98560028 * d) * rad
        let moonAnomaly = (134.963 + 13.064993 * d) * rad
        let meanElongation = (297.8502 + 12.190749 * d) * rad
        let latitudeArgument = (93.272 + 13.22935 * d) * rad
        let moonLongitude = 218.316 + 13.176396 * d
            + 6.289 * sin(moonAnomaly)
            + 1.274 * sin(2 * meanElongation - moonAnomaly)
            + 0.658 * sin(2 * meanElongation)
            + 0.214 * sin(2 * moonAnomaly)
            - 0.186 * sin(sunAnomaly)
            - 0.114 * sin(2 * latitudeArgument)
        let sunLongitude = 280.459 + 0.98564736 * d
            + 1.915 * sin(sunAnomaly)
            + 0.02 * sin(2 * sunAnomaly)
        return normalizedPhase((moonLongitude - sunLongitude) / 360)
    }

    private func normalizedPhase(_ value: Double) -> Double {
        let phase = value - floor(value)
        return phase < 0 ? phase + 1 : phase
    }
}
