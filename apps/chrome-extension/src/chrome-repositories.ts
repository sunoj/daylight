/**
 * Chrome storage-backed repositories for the extension client.
 * Exports: createChromeRepositories, ChromeRepositories
 * Deps: Chrome storage API, domain contracts, core mark keys, storage ports
 */

import { createDateMarkKey, getMarksForDate } from "@daylight/core-calendar";
import {
  createDiaryThought,
  DEFAULT_USER_SETTINGS,
  diaryThoughtTimestamp,
  ok,
  sortDiaryThoughtsNewestFirst,
} from "@daylight/domain";
import type { DateMark, HolidayColorId, HolidayDaysBySubscription, HolidaySubscription, Language, LocalDateKey, PublicCalendarDay, UserSettings } from "@daylight/domain";
import type { DaylightRepositories } from "@daylight/storage";
import { readDiaryThoughts, writeDiaryThoughts } from "./diary-storage";
import type { ToolbarTheme } from "./icon-theme";
import { resolveBrowserLanguage } from "./locale";

const SETTINGS_KEY = "settings";
const MARKS_KEY = "marks";
const PUBLIC_DAYS_KEY = "publicDays";
const HOLIDAY_DAYS_BY_SUBSCRIPTION_KEY = "holidayDaysBySubscription";
const TOOLBAR_THEME_KEY = "toolbarTheme";
const HOLIDAY_COLORS: readonly HolidayColorId[] = ["rust", "stone", "olive", "amber", "green"];

export interface ChromeRepositories extends DaylightRepositories {
  readonly toolbarTheme: {
    getTheme(): Promise<ToolbarTheme>;
    saveTheme(theme: ToolbarTheme): Promise<void>;
  };
}

export function createChromeRepositories(): ChromeRepositories {
  return {
    settings: {
      async getSettings() {
        const stored = await chrome.storage.sync.get(SETTINGS_KEY);
        return ok(parseSettings(stored[SETTINGS_KEY]));
      },
      async saveSettings(settings) {
        await chrome.storage.sync.set({ [SETTINGS_KEY]: settings });
        return ok(settings);
      },
    },
    marks: {
      async listMarks() {
        return ok(await readMarks());
      },
      async listMarksForDate(date) {
        return ok(getMarksForDate(date, await readMarks()));
      },
      async saveMark(mark) {
        const marks = await readMarks();
        const nextMarks = new Map(marks.map((item) => [createDateMarkKey(item), item]));
        nextMarks.set(createDateMarkKey(mark), mark);
        await writeLocal(MARKS_KEY, [...nextMarks.values()]);
        return ok(mark);
      },
      async deleteMark(mark) {
        const marks = await readMarks();
        const nextMarks = marks.filter((item) => createDateMarkKey(item) !== createDateMarkKey(mark));
        await writeLocal(MARKS_KEY, nextMarks);
        return ok(undefined);
      },
    },
    diary: {
      async listThoughtsForDate(date) {
        const thoughts = await readDiaryThoughts();
        return ok(sortDiaryThoughtsNewestFirst(thoughts.filter((item) => item.date === date)));
      },
      async listAllThoughts() {
        const thoughts = await readDiaryThoughts();
        return ok([...thoughts].sort((left, right) => left.date.localeCompare(right.date) || left.createdAt.localeCompare(right.createdAt)));
      },
      async addThought(date, content, done) {
        const thoughts = await readDiaryThoughts();
        const thought = createDiaryThought(date, content, done);
        await writeDiaryThoughts([...thoughts, thought]);
        return ok(thought);
      },
      async toggleThought(id) {
        const thoughts = await readDiaryThoughts();
        const index = thoughts.findIndex((item) => item.id === id);
        const current = index >= 0 ? thoughts[index] : undefined;
        if (!current || current.done === undefined) return ok(undefined);
        const next = [...thoughts];
        next[index] = { ...current, done: !current.done, updatedAt: diaryThoughtTimestamp() };
        await writeDiaryThoughts(next);
        return ok(undefined);
      },
      async deleteThought(id) {
        const thoughts = await readDiaryThoughts();
        await writeDiaryThoughts(thoughts.filter((item) => item.id !== id));
        return ok(undefined);
      },
    },
    publicCalendar: {
      async listPublicDays() {
        return ok(await readPublicDays());
      },
      async replacePublicDays(days) {
        await writeLocal(PUBLIC_DAYS_KEY, days);
        return ok(days);
      },
    },
    holidays: {
      async listSubscriptions() {
        const settings = await readSettings();
        return ok(settings.holidaySubscriptions);
      },
      async saveSubscriptions(subscriptions) {
        const settings = await readSettings();
        const next = { ...settings, holidaySubscriptions: [...subscriptions] };
        await chrome.storage.sync.set({ [SETTINGS_KEY]: next });
        return ok(next.holidaySubscriptions);
      },
      async replaceDaysForSubscription(subscriptionId, days) {
        const bySubscription = await readHolidayDaysBySubscription();
        await writeLocal(HOLIDAY_DAYS_BY_SUBSCRIPTION_KEY, { ...bySubscription, [subscriptionId]: days });
        return ok(days);
      },
      async removeDaysForSubscription(subscriptionId) {
        const bySubscription = { ...await readHolidayDaysBySubscription() };
        delete bySubscription[subscriptionId];
        await writeLocal(HOLIDAY_DAYS_BY_SUBSCRIPTION_KEY, bySubscription);
        return ok(undefined);
      },
      async holidayHits(date) {
        const settings = await readSettings();
        const bySubscription = await readHolidayDaysBySubscription();
        const hits = settings.holidaySubscriptions.filter((item) => item.enabled).flatMap((subscription) => {
          return (bySubscription[subscription.id] ?? [])
            .filter((day) => day.date === date)
            .map((day) => ({ subscription, day }));
        });
        return ok(hits);
      },
    },
    toolbarTheme: {
      async getTheme() {
        const stored = await chrome.storage.local.get(TOOLBAR_THEME_KEY);
        return parseToolbarTheme(stored[TOOLBAR_THEME_KEY]);
      },
      async saveTheme(theme) {
        await chrome.storage.local.set({ [TOOLBAR_THEME_KEY]: theme });
      },
    },
  };
}

async function readSettings(): Promise<UserSettings> {
  const stored = await chrome.storage.sync.get(SETTINGS_KEY);
  return parseSettings(stored[SETTINGS_KEY]);
}

async function readMarks(): Promise<readonly DateMark[]> {
  const stored = await chrome.storage.local.get(MARKS_KEY);
  const value = stored[MARKS_KEY];
  return Array.isArray(value) ? value.filter(isDateMark) : [];
}

async function readPublicDays(): Promise<readonly PublicCalendarDay[]> {
  const stored = await chrome.storage.local.get(PUBLIC_DAYS_KEY);
  const value = stored[PUBLIC_DAYS_KEY];
  return Array.isArray(value) ? value.filter(isPublicDay) : [];
}

async function readHolidayDaysBySubscription(): Promise<HolidayDaysBySubscription> {
  const stored = await chrome.storage.local.get(HOLIDAY_DAYS_BY_SUBSCRIPTION_KEY);
  const value = stored[HOLIDAY_DAYS_BY_SUBSCRIPTION_KEY];
  if (!isRecord(value)) return {};
  return Object.fromEntries(Object.entries(value).map(([id, days]) => [
    id,
    Array.isArray(days) ? days.filter(isPublicDay) : [],
  ]));
}

async function writeLocal(key: string, value: unknown): Promise<void> {
  await chrome.storage.local.set({ [key]: value });
}

export function parseSettings(value: unknown, fallbackLanguage = resolveBrowserLanguage()): UserSettings {
  const defaults = defaultSettings(fallbackLanguage);
  if (!isRecord(value)) return defaults;
  return {
    language: parseLanguage(value.language, fallbackLanguage),
    colorScheme: value.colorScheme === "light" || value.colorScheme === "dark" ? value.colorScheme : "system",
    showLunarDate: getBoolean(value.showLunarDate, DEFAULT_USER_SETTINGS.showLunarDate),
    autoOpenTodayDetail: getBoolean(value.autoOpenTodayDetail, DEFAULT_USER_SETTINGS.autoOpenTodayDetail),
    actionIconMode: value.actionIconMode === "emoji" || value.actionIconMode === "moonPhase" ? value.actionIconMode : "date",
    showWeekNumbers: getBoolean(value.showWeekNumbers, DEFAULT_USER_SETTINGS.showWeekNumbers),
    calendarType: parseCalendarType(value.calendarType),
    holidaySubscriptions: parseHolidaySubscriptions(value.holidaySubscriptions),
    holidayUpdateWeekly: getBoolean(value.holidayUpdateWeekly, DEFAULT_USER_SETTINGS.holidayUpdateWeekly),
  };
}

function defaultSettings(language: Language): UserSettings {
  return { ...DEFAULT_USER_SETTINGS, language };
}

function parseToolbarTheme(value: unknown): ToolbarTheme {
  return value === "light" || value === "dark" ? value : "unknown";
}

function parseLanguage(value: unknown, fallback: Language): Language {
  return value === "zh" || value === "zh-Hant" || value === "en" || value === "th" ? value : fallback;
}

function parseCalendarType(value: unknown): UserSettings["calendarType"] {
  if (value === "us" || value === "arabic" || value === "hebrew") return value;
  return "iso8601";
}

function getBoolean(value: unknown, fallback: boolean): boolean {
  return typeof value === "boolean" ? value : fallback;
}

function parseHolidaySubscriptions(value: unknown): readonly HolidaySubscription[] {
  if (!Array.isArray(value)) return [];
  return value.filter(isHolidaySubscription);
}

function isHolidaySubscription(value: unknown): value is HolidaySubscription {
  return isRecord(value)
    && typeof value.id === "string"
    && typeof value.sourceId === "string"
    && typeof value.customURL === "string"
    && isHolidayColor(value.colorId)
    && typeof value.enabled === "boolean"
    && typeof value.name === "string";
}

function isHolidayColor(value: unknown): value is HolidayColorId {
  return typeof value === "string" && HOLIDAY_COLORS.includes(value as HolidayColorId);
}

function isDateMark(value: unknown): value is DateMark {
  if (!isRecord(value) || typeof value.content !== "string") return false;
  if (value.type === "yearly") return typeof value.month === "number" && typeof value.day === "number";
  if (value.type === "monthly") return typeof value.day === "number";
  return value.type === "oneTime" && typeof value.date === "string";
}

function isPublicDay(value: unknown): value is PublicCalendarDay {
  return isRecord(value) && typeof value.date === "string" && typeof value.type === "string" && typeof value.isImportant === "boolean";
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
