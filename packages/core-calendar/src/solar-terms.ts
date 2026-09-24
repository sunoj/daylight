/**
 * Solar term calculation and localized term labels.
 * Exports: getSolarTerm, getSolarTermLabelZh
 * Deps: domain calendar types, date-key helpers, constants
 */

import type { LocalDateKey, SolarTermName } from "@daylight/domain";
import { SOLAR_TERM_LABELS_ZH, SOLAR_TERM_NAMES } from "./constants";
import {
  SOLAR_TERM_BASE_DAYS,
  SOLAR_TERM_TABLE,
  SOLAR_TERM_TABLE_END_YEAR,
  SOLAR_TERM_TABLE_START_YEAR,
} from "./solar-term-table";
import { parseLocalDateKey } from "./date-key";

const SOLAR_TERM_MINUTE_OFFSETS = [
  0, 21208, 42467, 63836, 85337, 107014, 128867, 150921, 173149, 195551, 218072,
  240693, 263343, 285989, 308563, 331033, 353350, 375494, 397447, 419210, 440795,
  462224, 483532, 504758,
] as const;

const SOLAR_TERM_BASE_UTC_MS = Date.UTC(1900, 0, 6, 2, 5);
const TROPICAL_YEAR_MS = 31_556_925_974.7;

export function getSolarTerm(date: LocalDateKey): SolarTermName | undefined {
  const { year, month, day } = parseLocalDateKey(date);
  const firstTermIndex = (month - 1) * 2;
  const firstTermDay = getSolarTermDay(year, firstTermIndex);
  if (day === firstTermDay) return SOLAR_TERM_NAMES[firstTermIndex];

  const secondTermIndex = firstTermIndex + 1;
  const secondTermDay = getSolarTermDay(year, secondTermIndex);
  if (day === secondTermDay) return SOLAR_TERM_NAMES[secondTermIndex];

  return undefined;
}

export function getSolarTermLabelZh(solarTerm: SolarTermName): string {
  return SOLAR_TERM_LABELS_ZH[solarTerm];
}

function getSolarTermDay(year: number, termIndex: number): number {
  if (year >= SOLAR_TERM_TABLE_START_YEAR && year <= SOLAR_TERM_TABLE_END_YEAR) {
    const row = SOLAR_TERM_TABLE[year - SOLAR_TERM_TABLE_START_YEAR];
    const baseDay = SOLAR_TERM_BASE_DAYS[termIndex];
    const offsetChar = row?.[termIndex];
    if (baseDay === undefined || offsetChar === undefined) {
      throw new Error(`Invalid solar term index: ${termIndex}`);
    }
    return baseDay + Number(offsetChar);
  }
  // Outside the table the legacy linear formula is used; it is only accurate
  // to about ±1 day and exists so distant calendar browsing stays populated.
  const offsetMinutes = SOLAR_TERM_MINUTE_OFFSETS[termIndex];
  if (offsetMinutes === undefined) throw new Error(`Invalid solar term index: ${termIndex}`);
  const yearsSinceBase = year - 1900;
  const termUtcMs = SOLAR_TERM_BASE_UTC_MS + yearsSinceBase * TROPICAL_YEAR_MS + offsetMinutes * 60_000;
  return new Date(termUtcMs).getUTCDate();
}
