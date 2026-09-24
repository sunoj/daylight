/**
 * Popup state loading and mutation helpers.
 * Exports: PopupState, loadPopupState, navigation helpers
 * Deps: domain types, core date helpers, storage repositories
 */

import { addDays, getVisibleMonthRange, makeLocalDateKey, parseLocalDateKey } from "@daylight/core-calendar";
import type {
  CalendarViewMode,
  DateMark,
  DiaryThought,
  HolidayHit,
  LocalDateKey,
  PublicCalendarDay,
  UserSettings,
} from "@daylight/domain";
import { addVisibleMonths, calendarPeriod, nextViewMode } from "./calendar-period";
import type { DaylightRepositories } from "@daylight/storage";
import {
  CALENDAR_NAVIGATION,
  navigateTo,
  popScreen,
  pushScreen,
  type PopupNavigation,
  type PopupScreen,
} from "./popup-router";

export interface PopupState {
  readonly selectedDate: LocalDateKey;
  readonly visibleYear: number;
  readonly visibleMonth: number;
  readonly viewMode: CalendarViewMode;
  readonly settings: UserSettings;
  readonly marks: readonly DateMark[];
  readonly publicDays: readonly PublicCalendarDay[];
  readonly holidayHits: readonly HolidayHit[];
  readonly diaryThoughts: readonly DiaryThought[];
  readonly navigation: PopupNavigation;
}

export async function loadPopupState(
  repositories: DaylightRepositories,
  previous?: Pick<PopupState, "selectedDate" | "visibleYear" | "visibleMonth" | "viewMode" | "navigation">,
): Promise<PopupState> {
  const selectedDate = previous?.selectedDate ?? getTodayKey();
  const selectedParts = parseLocalDateKey(selectedDate);
  const visibleYear = previous?.visibleYear ?? selectedParts.year;
  const visibleMonth = previous?.visibleMonth ?? selectedParts.month;
  const viewMode = previous?.viewMode ?? "month";

  const settings = await unwrap(repositories.settings.getSettings());
  const [marks, publicDays, holidayHits, diaryThoughts] = await Promise.all([
    unwrap(repositories.marks.listMarks()),
    unwrap(repositories.publicCalendar.listPublicDays()),
    loadVisibleHolidayHits(repositories, settings, visibleYear, visibleMonth, selectedDate),
    unwrap(repositories.diary.listThoughtsForDate(selectedDate)),
  ]);

  return {
    selectedDate,
    visibleYear,
    visibleMonth,
    viewMode,
    settings,
    marks,
    publicDays,
    holidayHits,
    diaryThoughts,
    navigation: previous?.navigation ?? CALENDAR_NAVIGATION,
  };
}

export function moveMonth(state: PopupState, delta: number): PopupViewPatch {
  const step = calendarPeriod(state.visibleYear, state.visibleMonth, state.viewMode)[delta < 0 ? "previousStepMonths" : "nextStepMonths"];
  const next = addVisibleMonths(state.visibleYear, state.visibleMonth, step);
  return keepOverlay(state, {
    selectedDate: state.selectedDate,
    visibleYear: next.year,
    visibleMonth: next.month,
    viewMode: state.viewMode,
  });
}

export function selectDate(state: PopupState, selectedDate: LocalDateKey): PopupViewPatch {
  const parts = parseLocalDateKey(selectedDate);
  return {
    selectedDate,
    visibleYear: parts.year,
    visibleMonth: parts.month,
    viewMode: "month",
    navigation: pushScreen(state.navigation, { kind: "detail" }),
  };
}

export function jumpToToday(): PopupViewPatch {
  const today = getTodayKey();
  const parts = parseLocalDateKey(today);
  return {
    selectedDate: today,
    visibleYear: parts.year,
    visibleMonth: parts.month,
    viewMode: "month",
    navigation: CALENDAR_NAVIGATION,
  };
}

export function moveDay(state: PopupState, delta: number): PopupViewPatch {
  const selectedDate = addDays(state.selectedDate, delta);
  const parts = parseLocalDateKey(selectedDate);
  return {
    selectedDate,
    visibleYear: parts.year,
    visibleMonth: parts.month,
    viewMode: "month",
    navigation: state.navigation,
  };
}

export function zoomOut(state: PopupState): PopupViewPatch {
  const nextMode = nextViewMode(state.viewMode);
  if (!nextMode) return keepOverlay(state, keepView(state));
  return keepOverlay(state, { ...keepView(state), viewMode: nextMode });
}

export function zoomIn(state: PopupState): PopupViewPatch {
  const order: readonly CalendarViewMode[] = ["month", "year", "decade", "century"];
  const index = order.indexOf(state.viewMode);
  if (index <= 0) return keepOverlay(state, keepView(state));
  const previousMode = order[index - 1];
  if (!previousMode) return keepOverlay(state, keepView(state));
  return keepOverlay(state, { ...keepView(state), viewMode: previousMode });
}

export function selectPeriod(
  state: PopupState,
  year: number,
  month: number,
  nextMode: CalendarViewMode,
): PopupViewPatch {
  const selectedDate = makeLocalDateKey(year, month, 1);
  return keepOverlay(state, {
    selectedDate,
    visibleYear: year,
    visibleMonth: month,
    viewMode: nextMode,
  });
}

export function jumpToCurrentMonth(state: PopupState): PopupViewPatch {
  const now = new Date();
  return {
    ...keepView(state),
    visibleYear: now.getFullYear(),
    visibleMonth: now.getMonth() + 1,
    navigation: state.navigation,
  };
}

export function openScreen(state: PopupState, screen: PopupScreen["kind"]): PopupViewPatch {
  return { ...keepView(state), navigation: navigateTo(state.navigation, screen) };
}

export function goBack(state: PopupState): PopupViewPatch {
  return { ...keepView(state), navigation: popScreen(state.navigation) };
}

export function getNextDate(date: LocalDateKey, days: number): LocalDateKey {
  return addDays(date, days);
}

type PopupViewPatch = Pick<PopupState, "selectedDate" | "visibleYear" | "visibleMonth" | "viewMode" | "navigation">;

function getTodayKey(): LocalDateKey {
  const now = new Date();
  return makeLocalDateKey(now.getFullYear(), now.getMonth() + 1, now.getDate());
}

async function unwrap<T>(promise: Promise<{ readonly ok: true; readonly value: T } | { readonly ok: false }>): Promise<T> {
  const result = await promise;
  if (!result.ok) throw new Error("Repository operation failed.");
  return result.value;
}

async function loadVisibleHolidayHits(
  repositories: DaylightRepositories,
  settings: UserSettings,
  year: number,
  month: number,
  selectedDate: LocalDateKey,
): Promise<readonly HolidayHit[]> {
  const dates = new Set(visibleDates(year, month, settings).concat(selectedDate));
  const results = await Promise.all([...dates].map((date) => unwrap(repositories.holidays.holidayHits(date))));
  return results.flat();
}

function visibleDates(year: number, month: number, settings: UserSettings): readonly LocalDateKey[] {
  const [start, end] = getVisibleMonthRange(year, month, settings.calendarType);
  return datesBetween(start, end);
}

function datesBetween(start: LocalDateKey, end: LocalDateKey): readonly LocalDateKey[] {
  const dates: LocalDateKey[] = [];
  for (let date = start; date <= end; date = addDays(date, 1)) dates.push(date);
  return dates;
}

function keepView(state: PopupState): Pick<PopupState, "selectedDate" | "visibleYear" | "visibleMonth" | "viewMode"> {
  return {
    selectedDate: state.selectedDate,
    visibleYear: state.visibleYear,
    visibleMonth: state.visibleMonth,
    viewMode: state.viewMode,
  };
}

function keepOverlay(
  state: PopupState,
  next: Pick<PopupState, "selectedDate" | "visibleYear" | "visibleMonth" | "viewMode">,
): PopupViewPatch {
  return { ...next, navigation: state.navigation };
}
