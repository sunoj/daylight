/**
 * Detail page state loading.
 * Exports: DetailState, loadDetailState
 * Deps: domain types, storage repositories, holiday detail helpers
 */

import { makeLocalDateKey } from "@daylight/core-calendar";
import type { DateMark, DiaryThought, HolidayDetailEntry, HolidayHit, LocalDateKey, PublicCalendarDay, UserSettings } from "@daylight/domain";
import type { DaylightRepositories } from "@daylight/storage";
import { getHolidayDetailEntries } from "./holiday-detail";

export interface DetailState {
  readonly selectedDate: LocalDateKey;
  readonly settings: UserSettings;
  readonly selectedMarks: readonly DateMark[];
  readonly diaryThoughts: readonly DiaryThought[];
  readonly publicDays: readonly PublicCalendarDay[];
  readonly holidayHits: readonly HolidayHit[];
  readonly selectedHolidayEntries: readonly HolidayDetailEntry[];
}

export async function loadDetailState(
  repositories: DaylightRepositories,
  selectedDate: LocalDateKey,
): Promise<DetailState> {
  const settings = await unwrap(repositories.settings.getSettings());
  const [selectedMarks, diaryThoughts, publicDays, holidayHits] = await Promise.all([
    unwrap(repositories.marks.listMarksForDate(selectedDate)),
    unwrap(repositories.diary.listThoughtsForDate(selectedDate)),
    unwrap(repositories.publicCalendar.listPublicDays()),
    unwrap(repositories.holidays.holidayHits(selectedDate)),
  ]);

  return {
    selectedDate,
    settings,
    selectedMarks,
    diaryThoughts,
    publicDays,
    holidayHits,
    selectedHolidayEntries: getHolidayDetailEntries(selectedDate, holidayHits, publicDays, settings.holidaySubscriptions),
  };
}

async function unwrap<T>(promise: Promise<{ readonly ok: true; readonly value: T } | { readonly ok: false }>): Promise<T> {
  const result = await promise;
  if (!result.ok) throw new Error("Repository operation failed.");
  return result.value;
}

export function makeTodayKey(): LocalDateKey {
  const now = new Date();
  return makeLocalDateKey(now.getFullYear(), now.getMonth() + 1, now.getDate());
}
