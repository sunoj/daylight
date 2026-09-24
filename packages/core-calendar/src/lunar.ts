/**
 * Chinese lunar calendar conversion for Daylight date details.
 * Exports: getLunarDate, formatLunarDateZh
 * Deps: domain calendar types, date-key helpers, lunar constants
 */

import type { LocalDateKey, LunarDate, Result } from "@daylight/domain";
import { err, ok } from "@daylight/domain";
import {
  EARTHLY_BRANCHES,
  HEAVENLY_STEMS,
  LUNAR_BASE_UTC_MS,
  LUNAR_DAY_DIGITS,
  LUNAR_MONTH_LABELS,
  LUNAR_YEAR_DATA,
  MS_PER_DAY,
} from "./constants";
import { getSolarTerm, getSolarTermLabelZh } from "./solar-terms";
import { parseLocalDateKey, toUtcDate } from "./date-key";

export function getLunarDate(date: LocalDateKey): Result<LunarDate> {
  const { year } = parseLocalDateKey(date);
  // The lookup table starts at lunar new year 1949 (1949-01-29); earlier days
  // of 1949 belong to lunar year 1948, which the table cannot represent.
  if (year < 1949 || year > 2100 || toUtcDate(date).getTime() < LUNAR_BASE_UTC_MS) {
    return err({ code: "invalid-date", message: "Lunar conversion supports 1949-01-29 through 2100-12-31." });
  }

  const lunarParts = calculateLunarParts(date);
  if (!lunarParts) {
    return err({ code: "invalid-date", message: `Unable to calculate lunar date for ${date}.` });
  }

  const solarTerm = getSolarTerm(date);
  return ok({
    yearName: getYearName(lunarParts.year),
    monthName: getMonthName(lunarParts.month),
    dayName: getDayName(lunarParts.day),
    ...(solarTerm ? { solarTerm } : {}),
  });
}

export function formatLunarDateZh(lunarDate: LunarDate): string {
  // solarTerm is the SolarTermName enum ("minor-heat"); render it as Chinese
  // ("小暑"), not the raw key.
  const term = lunarDate.solarTerm ? ` ${getSolarTermLabelZh(lunarDate.solarTerm)}` : "";
  return `${lunarDate.yearName}年 ${lunarDate.monthName}月${lunarDate.dayName}${term}`;
}

function calculateLunarParts(date: LocalDateKey): { year: number; month: number | string; day: number } | null {
  let daySpan = Math.ceil((toUtcDate(date).getTime() - LUNAR_BASE_UTC_MS) / MS_PER_DAY) + 1;
  let lunarYear = 0;

  for (let index = 0; index < LUNAR_YEAR_DATA.length; index += 1) {
    const yearData = LUNAR_YEAR_DATA[index];
    if (yearData === undefined) return null;
    daySpan -= getLunarYearDays(yearData);
    if (daySpan <= 0) {
      lunarYear = 1949 + index;
      daySpan += getLunarYearDays(yearData);
      break;
    }
  }

  const yearData = LUNAR_YEAR_DATA[lunarYear - 1949];
  if (yearData === undefined) return null;

  const lunarMonth = findLunarMonth(yearData, daySpan);
  if (!lunarMonth) return null;
  return { year: lunarYear, month: lunarMonth.month, day: lunarMonth.day };
}

function findLunarMonth(yearData: number, daySpan: number): { month: number | string; day: number } | null {
  const monthDays = getLunarYearMonths(yearData);
  for (let index = 0; index < monthDays.length; index += 1) {
    const days = monthDays[index];
    if (days === undefined) return null;
    daySpan -= days;
    if (daySpan > 0) continue;
    const leapMonth = getLeapMonth(yearData);
    return { month: getMonthNumber(index, leapMonth), day: daySpan + days };
  }
  return null;
}

function getMonthNumber(index: number, leapMonth: number | null): number | string {
  if (!leapMonth || leapMonth > index) return index + 1;
  if (leapMonth === index) return `leap-${index}`;
  return index;
}

function getLeapMonth(yearData: number): number | null {
  const leapMonth = yearData & 0x0f;
  return leapMonth === 0 ? null : leapMonth;
}

function getLeapMonthDays(yearData: number): number {
  return getLeapMonth(yearData) ? (yearData & 0xf0000 ? 30 : 29) : 0;
}

function getLunarYearDays(yearData: number): number {
  let totalDays = 0;
  for (let mask = 0x8000; mask > 0x8; mask >>= 1) {
    totalDays += yearData & mask ? 30 : 29;
  }
  return totalDays + getLeapMonthDays(yearData);
}

function getLunarYearMonths(yearData: number): readonly number[] {
  const months: number[] = [];
  for (let mask = 0x8000; mask > 0x8; mask >>= 1) {
    months.push(yearData & mask ? 30 : 29);
  }
  const leapMonth = getLeapMonth(yearData);
  if (leapMonth) months.splice(leapMonth, 0, getLeapMonthDays(yearData));
  return months;
}

function getYearName(year: number): string {
  const stemIndex = (year - 4) % 10;
  const branchIndex = (year - 4) % 12;
  return `${HEAVENLY_STEMS[stemIndex]}${EARTHLY_BRANCHES[branchIndex]}`;
}

function getMonthName(month: number | string): string {
  if (typeof month === "string") {
    const leapMonth = Number(month.replace("leap-", ""));
    return `闰${LUNAR_MONTH_LABELS[leapMonth - 1]}`;
  }
  return LUNAR_MONTH_LABELS[month - 1] ?? "";
}

function getDayName(day: number): string {
  if (day < 11) return `${LUNAR_DAY_DIGITS[10]}${LUNAR_DAY_DIGITS[day - 1]}`;
  if (day < 20) return `${LUNAR_DAY_DIGITS[9]}${LUNAR_DAY_DIGITS[day - 11]}`;
  if (day === 20) return `${LUNAR_DAY_DIGITS[1]}${LUNAR_DAY_DIGITS[9]}`;
  if (day < 30) return `${LUNAR_DAY_DIGITS[11]}${LUNAR_DAY_DIGITS[day - 21]}`;
  return `${LUNAR_DAY_DIGITS[2]}${LUNAR_DAY_DIGITS[9]}`;
}
