/**
 * Storage repository contracts for all Daylight clients.
 * Exports: SettingsRepository, MarksRepository, DiaryRepository, PublicCalendarRepository
 * Deps: shared domain types
 */

import type {
  DateMark,
  DiaryThought,
  HolidayHit,
  HolidaySubscription,
  LocalDateKey,
  PublicCalendarDay,
  Result,
  UserSettings,
} from "@daylight/domain";

export interface SettingsRepository {
  getSettings(): Promise<Result<UserSettings>>;
  saveSettings(settings: UserSettings): Promise<Result<UserSettings>>;
}

export interface MarksRepository {
  listMarks(): Promise<Result<readonly DateMark[]>>;
  listMarksForDate(date: LocalDateKey): Promise<Result<readonly DateMark[]>>;
  saveMark(mark: DateMark): Promise<Result<DateMark>>;
  deleteMark(mark: DateMark): Promise<Result<void>>;
}

export interface DiaryRepository {
  listThoughtsForDate(date: LocalDateKey): Promise<Result<readonly DiaryThought[]>>;
  listAllThoughts(): Promise<Result<readonly DiaryThought[]>>;
  addThought(date: LocalDateKey, content: string, done?: boolean): Promise<Result<DiaryThought>>;
  toggleThought(id: string): Promise<Result<void>>;
  deleteThought(id: string): Promise<Result<void>>;
}

export interface PublicCalendarRepository {
  listPublicDays(): Promise<Result<readonly PublicCalendarDay[]>>;
  replacePublicDays(days: readonly PublicCalendarDay[]): Promise<Result<readonly PublicCalendarDay[]>>;
}

export interface HolidayRepository {
  listSubscriptions(): Promise<Result<readonly HolidaySubscription[]>>;
  saveSubscriptions(subscriptions: readonly HolidaySubscription[]): Promise<Result<readonly HolidaySubscription[]>>;
  replaceDaysForSubscription(subscriptionId: string, days: readonly PublicCalendarDay[]): Promise<Result<readonly PublicCalendarDay[]>>;
  removeDaysForSubscription(subscriptionId: string): Promise<Result<void>>;
  holidayHits(date: LocalDateKey): Promise<Result<readonly HolidayHit[]>>;
}

export interface DaylightRepositories {
  readonly settings: SettingsRepository;
  readonly marks: MarksRepository;
  readonly diary: DiaryRepository;
  readonly publicCalendar: PublicCalendarRepository;
  readonly holidays: HolidayRepository;
}
