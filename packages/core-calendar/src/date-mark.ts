/**
 * Date mark matching helpers for yearly, monthly, and one-time marks.
 * Exports: getMarksForDate, createDateMarkKey
 * Deps: domain user data types, date-key helpers
 */

import type { DateMark, LocalDateKey } from "@daylight/domain";
import { parseLocalDateKey } from "./date-key";

export function getMarksForDate(date: LocalDateKey, marks: readonly DateMark[]): readonly DateMark[] {
  return marks.filter((mark) => doesMarkMatchDate(mark, date));
}

export function createDateMarkKey(mark: DateMark): string {
  if (mark.type === "yearly") return `yearly:${mark.month}-${mark.day}`;
  if (mark.type === "monthly") return `monthly:${mark.day}`;
  return `oneTime:${mark.date}`;
}

function doesMarkMatchDate(mark: DateMark, date: LocalDateKey): boolean {
  const parts = parseLocalDateKey(date);
  if (mark.type === "yearly") return mark.month === parts.month && mark.day === parts.day;
  if (mark.type === "monthly") return mark.day === parts.day;
  return mark.date === date;
}
