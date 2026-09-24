/**
 * Date primitives used at every app boundary.
 * Exports: LocalDateKey, TimeZoneId, YearMonthKey, Weekday
 * Deps: none
 */

export type LocalDateKey = string & { readonly __brand: "LocalDateKey" };
export type YearMonthKey = string & { readonly __brand: "YearMonthKey" };
export type TimeZoneId = string & { readonly __brand: "TimeZoneId" };

export type Weekday = 0 | 1 | 2 | 3 | 4 | 5 | 6;

export interface LocalDateParts {
  readonly year: number;
  readonly month: number;
  readonly day: number;
}

export interface DateRange {
  readonly startDate: LocalDateKey;
  readonly endDate: LocalDateKey;
}
