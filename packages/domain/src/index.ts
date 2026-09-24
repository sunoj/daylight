/**
 * Public barrel for shared Daylight domain contracts.
 * Exports: date, calendar, user data, settings, sync, and Result types
 * Deps: package-local domain modules
 */

export type { DomainError, DomainErrorCode, Result } from "./result";
export { err, ok } from "./result";

export type {
  DateRange,
  LocalDateKey,
  LocalDateParts,
  TimeZoneId,
  Weekday,
  YearMonthKey,
} from "./date";

export type {
  CalendarDay,
  CalendarType,
  CalendarViewMode,
  LunarDate,
  MoonPhase,
  MoonPhaseName,
  PublicCalendarDay,
  PublicCalendarDayType,
  SolarTermName,
} from "./calendar";

export type { DateMark, DateMarkChange, DateMarkType, DiaryEntry, DiaryThought, LegacyDiaryEntry } from "./user-data";
export {
  createDiaryThought,
  createDiaryThoughtId,
  decodeDiaryThought,
  decodeDiaryThoughts,
  diaryThoughtTimestamp,
  legacyDiaryThoughtId,
  migrateLegacyDiaryEntry,
  parseDiaryInput,
  sortDiaryThoughtsNewestFirst,
  sortDiaryThoughtsOldestFirst,
} from "./user-data";

export type { ActionIconMode, ColorScheme, Language, UserSettings } from "./settings";
export { DEFAULT_USER_SETTINGS } from "./settings";

export type {
  HolidayColorId,
  HolidayDaysBySubscription,
  HolidayDetailEntry,
  HolidayHit,
  HolidaySubscription,
} from "./holidays";

export type {
  RemoteDataSource,
  RemoteDataSourceKind,
  SyncState,
  SyncStatus,
} from "./sync";
