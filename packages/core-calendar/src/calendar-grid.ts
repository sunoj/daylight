/**
 * Month grid generation for Chrome and macOS calendar views.
 * Exports: buildMonthGrid, MonthGrid
 * Deps: domain calendar types, date-key and lunar helpers
 */

import type { CalendarDay, CalendarType, LocalDateKey, PublicCalendarDay } from "@daylight/domain";
import { FIRST_WEEKDAY_BY_CALENDAR } from "./constants";
import { addDays, getDaysInMonth, getWeekday, makeLocalDateKey, parseLocalDateKey, toUtcDate } from "./date-key";
import { getLunarDate } from "./lunar";

export interface BuildMonthGridInput {
  readonly year: number;
  readonly month: number;
  readonly today: LocalDateKey;
  readonly calendarType: CalendarType;
  readonly showLunarDate: boolean;
  readonly publicDays?: readonly PublicCalendarDay[];
}

export interface MonthGrid {
  readonly year: number;
  readonly month: number;
  readonly days: readonly CalendarDay[];
}

export function buildMonthGrid(input: BuildMonthGridInput): MonthGrid {
  const firstDate = makeLocalDateKey(input.year, input.month, 1);
  const gridStartDate = getGridStartDate(firstDate, input.calendarType);
  const publicDayByDate = new Map(input.publicDays?.map((day) => [day.date, day]));

  const days = Array.from({ length: 42 }, (_, offset) => {
    const date = addDays(gridStartDate, offset);
    return buildCalendarDay(date, input, publicDayByDate);
  });

  return { year: input.year, month: input.month, days };
}

function getGridStartDate(firstDate: LocalDateKey, calendarType: CalendarType): LocalDateKey {
  const firstWeekday = FIRST_WEEKDAY_BY_CALENDAR[calendarType];
  const offset = (getWeekday(firstDate) - firstWeekday + 7) % 7;
  return addDays(firstDate, -offset);
}

function buildCalendarDay(
  date: LocalDateKey,
  input: BuildMonthGridInput,
  publicDayByDate: ReadonlyMap<LocalDateKey, PublicCalendarDay>,
): CalendarDay {
  const parts = parseLocalDateKey(date);
  const lunarResult = input.showLunarDate ? getLunarDate(date) : undefined;
  const lunarDate = lunarResult?.ok ? lunarResult.value : undefined;
  const publicDay = publicDayByDate.get(date);
  return {
    date,
    weekday: getWeekday(date),
    isToday: date === input.today,
    isOutsideMonth: parts.month !== input.month,
    ...(lunarDate ? { lunarDate } : {}),
    ...(publicDay ? { publicDay } : {}),
  };
}

export function getVisibleMonthRange(year: number, month: number, calendarType: CalendarType): readonly [LocalDateKey, LocalDateKey] {
  const firstDate = makeLocalDateKey(year, month, 1);
  const gridStartDate = getGridStartDate(firstDate, calendarType);
  const lastDate = makeLocalDateKey(year, month, getDaysInMonth(year, month));
  const elapsedDays = Math.round((toUtcDate(lastDate).getTime() - toUtcDate(gridStartDate).getTime()) / 86_400_000);
  const endOffset = 41 - elapsedDays;
  return [gridStartDate, addDays(lastDate, endOffset)];
}
