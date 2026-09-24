/**
 * Local date key parsing, formatting, and arithmetic helpers.
 * Exports: parseLocalDateKey, makeLocalDateKey, addDays, getWeekday, getWeekNumber
 * Deps: domain date types, constants
 */

import type { CalendarType, LocalDateKey, LocalDateParts, Weekday, YearMonthKey } from "@daylight/domain";
import { FIRST_WEEKDAY_BY_CALENDAR, MS_PER_DAY } from "./constants";

export function makeLocalDateKey(year: number, month: number, day: number): LocalDateKey {
  const yyyy = String(year).padStart(4, "0");
  const mm = String(month).padStart(2, "0");
  const dd = String(day).padStart(2, "0");
  return `${yyyy}-${mm}-${dd}` as LocalDateKey;
}

export function makeYearMonthKey(year: number, month: number): YearMonthKey {
  const yyyy = String(year).padStart(4, "0");
  const mm = String(month).padStart(2, "0");
  return `${yyyy}-${mm}` as YearMonthKey;
}

export function parseLocalDateKey(date: LocalDateKey): LocalDateParts {
  const [year, month, day] = date.split("-").map((part) => Number(part));
  if (!year || !month || !day) throw new Error(`Invalid local date key: ${date}`);
  return { year, month, day };
}

export function toUtcDate(date: LocalDateKey): Date {
  const parts = parseLocalDateKey(date);
  return new Date(Date.UTC(parts.year, parts.month - 1, parts.day));
}

export function fromUtcDate(date: Date): LocalDateKey {
  return makeLocalDateKey(date.getUTCFullYear(), date.getUTCMonth() + 1, date.getUTCDate());
}

export function addDays(date: LocalDateKey, days: number): LocalDateKey {
  const nextUtcMs = toUtcDate(date).getTime() + days * MS_PER_DAY;
  return fromUtcDate(new Date(nextUtcMs));
}

export function getWeekday(date: LocalDateKey): Weekday {
  return toUtcDate(date).getUTCDay() as Weekday;
}

export function getDaysInMonth(year: number, month: number): number {
  return new Date(Date.UTC(year, month, 0)).getUTCDate();
}

/**
 * Week-of-year under the calendar type's week rule: weeks start on the rule's
 * first weekday, and week 1 is the first week with at least 4 days of the year
 * for ISO 8601 or the week containing January 1 for the other rules. Matches
 * Foundation's Calendar.weekOfYear used by the macOS client.
 */
export function getWeekNumber(date: LocalDateKey, calendarType: CalendarType): number {
  const firstWeekday = FIRST_WEEKDAY_BY_CALENDAR[calendarType];
  const minimumDaysInFirstWeek = calendarType === "iso8601" ? 4 : 1;
  const weekStart = addDays(date, -((getWeekday(date) - firstWeekday + 7) % 7));
  // The week belongs to whichever year this reference day falls in: the 4th
  // day of the week for ISO 8601, the last day for first-week-contains-Jan-1.
  const reference = addDays(weekStart, 7 - minimumDaysInFirstWeek);
  const { year } = parseLocalDateKey(reference);
  const dayOfYear = Math.round((toUtcDate(reference).getTime() - Date.UTC(year, 0, 1)) / MS_PER_DAY) + 1;
  return Math.floor((dayOfYear - 1) / 7) + 1;
}
