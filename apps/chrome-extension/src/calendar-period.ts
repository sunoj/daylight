/**
 * Period picker arithmetic, titles, and lunar labels for year/decade/century grids.
 * Exports: calendarPeriod, buildPeriodGridItems, lunar period label helpers
 * Deps: core-calendar, domain CalendarViewMode, locale display helpers
 */

import { getDaysInMonth, getLunarDate, makeLocalDateKey } from "@daylight/core-calendar";
import type { CalendarViewMode } from "@daylight/domain";
import { formatCalendarYear, monthShort, t } from "./locale";

export interface CalendarPeriodInfo {
  readonly title: string;
  readonly previousStepMonths: number;
  readonly nextStepMonths: number;
}

export interface PeriodGridItem {
  readonly title: string;
  readonly subtitle?: string;
  readonly year: number;
  readonly month: number;
  readonly nextMode: CalendarViewMode;
  readonly isOutsidePeriod: boolean;
  readonly isSelected: boolean;
}

export function calendarPeriod(year: number, month: number, mode: CalendarViewMode): CalendarPeriodInfo {
  switch (mode) {
    case "month":
      return {
        title: `${formatCalendarYear(year)}.${String(month).padStart(2, "0")}`,
        previousStepMonths: -1,
        nextStepMonths: 1,
      };
    case "year":
      return {
        title: formatCalendarYear(year),
        previousStepMonths: -12,
        nextStepMonths: 12,
      };
    case "decade": {
      const start = Math.floor(year / 10) * 10;
      return {
        title: `${formatCalendarYear(start)}–${formatCalendarYear(start + 9)}`,
        previousStepMonths: -120,
        nextStepMonths: 120,
      };
    }
    case "century": {
      const start = Math.floor(year / 100) * 100;
      return {
        title: `${formatCalendarYear(start)}–${formatCalendarYear(start + 99)}`,
        previousStepMonths: -1200,
        nextStepMonths: 1200,
      };
    }
  }
}

export function addVisibleMonths(year: number, month: number, delta: number): { readonly year: number; readonly month: number } {
  const monthIndex = month - 1 + delta;
  return {
    year: year + Math.floor(monthIndex / 12),
    month: ((monthIndex % 12) + 12) % 12 + 1,
  };
}

export function nextViewMode(mode: CalendarViewMode): CalendarViewMode | undefined {
  const order: readonly CalendarViewMode[] = ["month", "year", "decade", "century"];
  const index = order.indexOf(mode);
  return index >= 0 && index + 1 < order.length ? order[index + 1] : undefined;
}

export function previousViewMode(mode: CalendarViewMode): CalendarViewMode | undefined {
  const order: readonly CalendarViewMode[] = ["month", "year", "decade", "century"];
  const index = order.indexOf(mode);
  return index > 0 ? order[index - 1] : undefined;
}

export function buildPeriodGridItems(
  visibleYear: number,
  visibleMonth: number,
  selectedYear: number,
  selectedMonth: number,
  mode: CalendarViewMode,
  showLunarDate: boolean,
): readonly PeriodGridItem[] {
  switch (mode) {
    case "year":
      return Array.from({ length: 12 }, (_, index) => {
        const month = index + 1;
        const subtitle = showLunarDate ? lunarMonthSpan(visibleYear, month) : undefined;
        return {
          title: monthShort(month),
          ...(subtitle ? { subtitle } : {}),
          year: visibleYear,
          month,
          nextMode: "month" as const,
          isOutsidePeriod: false,
          isSelected: visibleYear === selectedYear && month === selectedMonth,
        };
      });
    case "decade": {
      const start = Math.floor(visibleYear / 10) * 10 - 1;
      const periodStart = start + 1;
      return Array.from({ length: 12 }, (_, index) => {
        const year = start + index;
        const subtitle = showLunarDate ? lunarYearName(year) : undefined;
        return {
          title: formatCalendarYear(year),
          ...(subtitle ? { subtitle } : {}),
          year,
          month: 1,
          nextMode: "year" as const,
          isOutsidePeriod: year < periodStart || year > periodStart + 9,
          isSelected: year === selectedYear,
        };
      });
    }
    case "century": {
      const start = Math.floor(visibleYear / 100) * 100 - 10;
      const periodStart = start + 10;
      return Array.from({ length: 12 }, (_, index) => {
        const decadeStart = start + index * 10;
        return {
          title: `${formatCalendarYear(decadeStart)}–${formatCalendarYear(decadeStart + 9)}`,
          year: decadeStart,
          month: 1,
          nextMode: "decade" as const,
          isOutsidePeriod: decadeStart < periodStart || decadeStart > periodStart + 90,
          isSelected: selectedYear >= decadeStart && selectedYear <= decadeStart + 9,
        };
      });
    }
    default:
      return [];
  }
}

/** 干支 year name at midsummer — the lunar year a Gregorian year is known by. */
export function lunarYearName(year: number): string | undefined {
  const lunar = getLunarDate(makeLocalDateKey(year, 7, 1));
  return lunar.ok ? t(`${lunar.value.yearName}年`) : undefined;
}

/** Lunar month span for a Gregorian month page, e.g. 五月–六月. */
export function lunarMonthSpan(year: number, month: number): string | undefined {
  const first = getLunarDate(makeLocalDateKey(year, month, 1));
  if (!first.ok) return undefined;
  const lastDay = getDaysInMonth(year, month);
  const last = getLunarDate(makeLocalDateKey(year, month, lastDay));
  if (!last.ok) return t(`${first.value.monthName}月`);
  if (last.value.monthName === first.value.monthName) return t(`${first.value.monthName}月`);
  return t(`${first.value.monthName}月–${last.value.monthName}月`);
}
