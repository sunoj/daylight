/**
 * Public barrel for pure Daylight calendar calculations.
 * Exports: date keys, lunar, solar terms, moon phase, grid, marks
 * Deps: package-local calculation modules
 */

export { getDayCellSubtitle } from "./calendar-day-subtitle";
export type { DayCellSubtitle } from "./calendar-day-subtitle";

export { buildMonthGrid, getVisibleMonthRange } from "./calendar-grid";
export type { BuildMonthGridInput, MonthGrid } from "./calendar-grid";

export {
  addDays,
  fromUtcDate,
  getDaysInMonth,
  getWeekday,
  getWeekNumber,
  makeLocalDateKey,
  makeYearMonthKey,
  parseLocalDateKey,
  toUtcDate,
} from "./date-key";

export { createDateMarkKey, getMarksForDate } from "./date-mark";
export { formatLunarDateZh, getLunarDate } from "./lunar";
export { getMoonAgeDays, getMoonPhase } from "./moon-phase";

export { holidayHitsForDate, resolvePublicDay } from "./public-day";
export { getSolarTerm, getSolarTermLabelZh } from "./solar-terms";
