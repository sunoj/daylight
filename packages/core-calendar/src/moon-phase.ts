/**
 * Moon phase calculation for app icons and date detail metadata.
 * Exports: getMoonPhase
 * Deps: domain calendar types, date-key helpers
 */

import type { LocalDateKey, MoonPhase, MoonPhaseName } from "@daylight/domain";
import { toUtcDate } from "./date-key";

const J2000_UTC_MS = Date.UTC(2000, 0, 1, 12);
const DEGREES_TO_RADIANS = Math.PI / 180;
const SYNODIC_MONTH_DAYS = 29.530588853;

export function getMoonAgeDays(date: LocalDateKey): number {
  return SYNODIC_MONTH_DAYS * getMoonPhase(date).phase;
}

export function getMoonPhase(date: LocalDateKey): MoonPhase {
  const daysSinceJ2000 = (toUtcDate(date).getTime() - J2000_UTC_MS) / 86_400_000;
  const normalizedPhase = normalizePhase(sunMoonElongationDegrees(daysSinceJ2000) / 360);
  const illumination = (1 - Math.cos(normalizedPhase * 2 * Math.PI)) / 2;
  return {
    name: classifyMoonPhase(normalizedPhase),
    illumination,
    phase: normalizedPhase,
  };
}

/**
 * Geocentric elongation of the Moon from the Sun in ecliptic longitude, using
 * the truncated series from Meeus, "Astronomical Algorithms" (low-precision
 * lunar longitude, ~0.3° ≈ 35 minutes of phase). The previous mean-phase
 * approximation drifted up to ±1 day from the true phase.
 */
function sunMoonElongationDegrees(daysSinceJ2000: number): number {
  const d = daysSinceJ2000;
  const sunAnomaly = (357.529 + 0.98560028 * d) * DEGREES_TO_RADIANS;
  const moonAnomaly = (134.963 + 13.064993 * d) * DEGREES_TO_RADIANS;
  const meanElongation = (297.8502 + 12.190749 * d) * DEGREES_TO_RADIANS;
  const latitudeArgument = (93.272 + 13.22935 * d) * DEGREES_TO_RADIANS;
  const moonLongitude =
    218.316 +
    13.176396 * d +
    6.289 * Math.sin(moonAnomaly) +
    1.274 * Math.sin(2 * meanElongation - moonAnomaly) +
    0.658 * Math.sin(2 * meanElongation) +
    0.214 * Math.sin(2 * moonAnomaly) -
    0.186 * Math.sin(sunAnomaly) -
    0.114 * Math.sin(2 * latitudeArgument);
  const sunLongitude =
    280.459 + 0.98564736 * d + 1.915 * Math.sin(sunAnomaly) + 0.02 * Math.sin(2 * sunAnomaly);
  return moonLongitude - sunLongitude;
}

function normalizePhase(value: number): number {
  const phase = value - Math.floor(value);
  return phase < 0 ? phase + 1 : phase;
}

function classifyMoonPhase(phase: number): MoonPhaseName {
  if (phase < 0.03 || phase >= 0.97) return "new";
  if (phase < 0.22) return "waxing-crescent";
  if (phase < 0.28) return "first-quarter";
  if (phase < 0.47) return "waxing-gibbous";
  if (phase < 0.53) return "full";
  if (phase < 0.72) return "waning-gibbous";
  if (phase < 0.78) return "last-quarter";
  return "waning-crescent";
}
