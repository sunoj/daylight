/**
 * Calendar, lunar, public-day, and moon phase domain models.
 * Exports: CalendarType, LunarDate, SolarTermName, PublicCalendarDay, MoonPhase
 * Deps: date primitives
 */

import type { LocalDateKey, Weekday } from "./date";

export type CalendarType = "iso8601" | "us" | "arabic" | "hebrew";

export type CalendarViewMode = "month" | "year" | "decade" | "century";

export type SolarTermName =
  | "spring-equinox"
  | "clear-and-bright"
  | "grain-rain"
  | "summer-begins"
  | "grain-full"
  | "grain-in-ear"
  | "summer-solstice"
  | "minor-heat"
  | "major-heat"
  | "autumn-begins"
  | "limit-of-heat"
  | "white-dew"
  | "autumn-equinox"
  | "cold-dew"
  | "frost-descent"
  | "winter-begins"
  | "minor-snow"
  | "major-snow"
  | "winter-solstice"
  | "minor-cold"
  | "major-cold"
  | "spring-begins"
  | "rain-water"
  | "insects-awaken";

export interface LunarDate {
  readonly yearName: string;
  readonly monthName: string;
  readonly dayName: string;
  readonly solarTerm?: SolarTermName;
}

export type PublicCalendarDayType = "holiday" | "workday" | "observance";

export interface PublicCalendarDay {
  readonly date: LocalDateKey;
  readonly type: PublicCalendarDayType;
  readonly name?: string;
  readonly description?: string;
  readonly sourceUrl?: string;
  readonly isImportant: boolean;
}

export type MoonPhaseName =
  | "new"
  | "waxing-crescent"
  | "first-quarter"
  | "waxing-gibbous"
  | "full"
  | "waning-gibbous"
  | "last-quarter"
  | "waning-crescent";

export interface MoonPhase {
  readonly name: MoonPhaseName;
  readonly illumination: number;
  readonly phase: number;
}

export interface CalendarDay {
  readonly date: LocalDateKey;
  readonly weekday: Weekday;
  readonly isToday: boolean;
  readonly isOutsideMonth: boolean;
  readonly lunarDate?: LunarDate;
  readonly publicDay?: PublicCalendarDay;
}
