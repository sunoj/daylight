/**
 * Public calendar day resolution shared by Daylight clients.
 * Exports: resolvePublicDay, holidayHitsForDate
 * Deps: domain holiday and calendar types
 */

import type { HolidayHit, LocalDateKey, PublicCalendarDay } from "@daylight/domain";

export function resolvePublicDay(
  date: LocalDateKey,
  holidayHits: readonly HolidayHit[],
  publicDays: readonly PublicCalendarDay[],
): PublicCalendarDay | undefined {
  const hits = holidayHitsForDate(date, holidayHits);
  if (hits.length > 0) return hits[0]?.day;
  return publicDays.find((day) => day.date === date);
}

export function holidayHitsForDate(
  date: LocalDateKey,
  holidayHits: readonly HolidayHit[],
): readonly HolidayHit[] {
  return holidayHits.filter((hit) => hit.day.date === date);
}
