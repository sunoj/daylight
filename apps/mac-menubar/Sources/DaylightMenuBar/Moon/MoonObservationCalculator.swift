// Local observer moon phase and sky-position approximation.
// Exports: ObservedMoonPhase, MoonObservationCalculator
// Deps: Foundation Date, ObserverLocation

import Foundation

struct ObservedMoonPhase: Equatable {
    let location: ObserverLocation
    let phaseName: String
    let ageDays: Double
    let illuminatedFraction: Double
    let phaseAngleDegrees: Double
    let altitudeDegrees: Double
    let azimuthDegrees: Double
    let parallacticAngleDegrees: Double
}

final class MoonObservationCalculator {
    private let synodicMonthDays = 29.530588853

    func observation(at date: Date, location: ObserverLocation) -> ObservedMoonPhase {
        let jd = julianDate(from: date)
        let days = jd - 2_451_545.0
        let sunLongitude = sunEclipticLongitude(days)
        let moon = moonCoordinates(days)
        let phaseAngle = normalizeDegrees(moon.longitudeDegrees - sunLongitude)
        let horizontal = horizontalCoordinates(jd: jd, moon: moon, location: location)
        return ObservedMoonPhase(
            location: location,
            phaseName: phaseName(phaseAngleDegrees: phaseAngle),
            ageDays: synodicMonthDays * phaseAngle / 360,
            illuminatedFraction: (1 - cos(degreesToRadians(phaseAngle))) / 2,
            phaseAngleDegrees: phaseAngle,
            altitudeDegrees: horizontal.altitude,
            azimuthDegrees: horizontal.azimuth,
            parallacticAngleDegrees: horizontal.parallacticAngle
        )
    }

    private func julianDate(from date: Date) -> Double {
        date.timeIntervalSince1970 / 86_400 + 2_440_587.5
    }

    private func sunEclipticLongitude(_ days: Double) -> Double {
        let meanAnomaly = degreesToRadians(normalizeDegrees(357.529 + 0.98560028 * days))
        let meanLongitude = normalizeDegrees(280.459 + 0.98564736 * days)
        return normalizeDegrees(meanLongitude + 1.915 * sin(meanAnomaly) + 0.020 * sin(2 * meanAnomaly))
    }

    private func moonCoordinates(_ days: Double) -> (rightAscension: Double, declination: Double, longitudeDegrees: Double) {
        let elements = moonOrbitalElements(days)
        let anomaly = eccentricAnomaly(elements.meanAnomaly, eccentricity: elements.eccentricity)
        let orbitalX = elements.semiMajorAxis * (cos(anomaly) - elements.eccentricity)
        let orbitalY = elements.semiMajorAxis * sqrt(1 - pow(elements.eccentricity, 2)) * sin(anomaly)
        let trueAnomaly = atan2(orbitalY, orbitalX)
        let distance = sqrt(pow(orbitalX, 2) + pow(orbitalY, 2))
        return equatorialCoordinates(elements: elements, trueAnomaly: trueAnomaly, distance: distance, days: days)
    }

    private func moonOrbitalElements(_ days: Double) -> MoonOrbitalElements {
        MoonOrbitalElements(
            nodeLongitude: degreesToRadians(normalizeDegrees(125.1228 - 0.0529538083 * days)),
            inclination: degreesToRadians(5.1454),
            periapsis: degreesToRadians(normalizeDegrees(318.0634 + 0.1643573223 * days)),
            semiMajorAxis: 60.2666,
            eccentricity: 0.0549,
            meanAnomaly: degreesToRadians(normalizeDegrees(115.3654 + 13.0649929509 * days))
        )
    }

    private func eccentricAnomaly(_ meanAnomaly: Double, eccentricity: Double) -> Double {
        meanAnomaly + eccentricity * sin(meanAnomaly) * (1 + eccentricity * cos(meanAnomaly))
    }

    private func equatorialCoordinates(
        elements: MoonOrbitalElements,
        trueAnomaly: Double,
        distance: Double,
        days: Double
    ) -> (rightAscension: Double, declination: Double, longitudeDegrees: Double) {
        let argument = trueAnomaly + elements.periapsis
        let ecliptic = eclipticCoordinates(elements: elements, argument: argument, distance: distance)
        let obliquity = degreesToRadians(23.4393 - 3.563e-7 * days)
        let longitude = atan2(ecliptic.y, ecliptic.x)
        let latitude = atan2(ecliptic.z, sqrt(pow(ecliptic.x, 2) + pow(ecliptic.y, 2)))
        let x = distance * cos(longitude) * cos(latitude)
        let y = distance * (sin(longitude) * cos(latitude) * cos(obliquity) - sin(latitude) * sin(obliquity))
        let z = distance * (sin(longitude) * cos(latitude) * sin(obliquity) + sin(latitude) * cos(obliquity))
        return (atan2(y, x), atan2(z, sqrt(pow(x, 2) + pow(y, 2))), normalizeDegrees(radiansToDegrees(longitude)))
    }

    private func eclipticCoordinates(
        elements: MoonOrbitalElements,
        argument: Double,
        distance: Double
    ) -> (x: Double, y: Double, z: Double) {
        let x = distance * (cos(elements.nodeLongitude) * cos(argument) - sin(elements.nodeLongitude) * sin(argument) * cos(elements.inclination))
        let y = distance * (sin(elements.nodeLongitude) * cos(argument) + cos(elements.nodeLongitude) * sin(argument) * cos(elements.inclination))
        let z = distance * sin(argument) * sin(elements.inclination)
        return (x, y, z)
    }

    private func horizontalCoordinates(
        jd: Double,
        moon: (rightAscension: Double, declination: Double, longitudeDegrees: Double),
        location: ObserverLocation
    ) -> (altitude: Double, azimuth: Double, parallacticAngle: Double) {
        let sidereal = degreesToRadians(normalizeDegrees(280.46061837 + 360.98564736629 * (jd - 2_451_545.0) + location.longitudeDegrees))
        let latitude = degreesToRadians(location.latitudeDegrees)
        let hourAngle = sidereal - moon.rightAscension
        let altitude = asin(sin(latitude) * sin(moon.declination) + cos(latitude) * cos(moon.declination) * cos(hourAngle))
        let azimuth = atan2(-sin(hourAngle), tan(moon.declination) * cos(latitude) - sin(latitude) * cos(hourAngle))
        let parallactic = atan2(sin(hourAngle), tan(latitude) * cos(moon.declination) - sin(moon.declination) * cos(hourAngle))
        return (radiansToDegrees(altitude), normalizeDegrees(radiansToDegrees(azimuth)), radiansToDegrees(parallactic))
    }

    private func phaseName(phaseAngleDegrees: Double) -> String {
        switch phaseAngleDegrees {
        case 0..<22.5, 337.5..<360: return "New Moon"
        case 22.5..<67.5: return "Waxing Crescent"
        case 67.5..<112.5: return "First Quarter"
        case 112.5..<157.5: return "Waxing Gibbous"
        case 157.5..<202.5: return "Full Moon"
        case 202.5..<247.5: return "Waning Gibbous"
        case 247.5..<292.5: return "Last Quarter"
        default: return "Waning Crescent"
        }
    }

    private func normalizeDegrees(_ value: Double) -> Double {
        let normalized = value.truncatingRemainder(dividingBy: 360)
        return normalized < 0 ? normalized + 360 : normalized
    }

    private func degreesToRadians(_ value: Double) -> Double {
        value * .pi / 180
    }

    private func radiansToDegrees(_ value: Double) -> Double {
        value * 180 / .pi
    }
}

private struct MoonOrbitalElements {
    let nodeLongitude: Double
    let inclination: Double
    let periapsis: Double
    let semiMajorAxis: Double
    let eccentricity: Double
    let meanAnomaly: Double
}
