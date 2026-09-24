/**
 * Calendar data mutations shared by popup, detail, and options pages.
 * Exports: saveSelectedMark, deleteMark, saveSelectedDiary, saveSettings, holiday ops
 * Deps: domain types, storage repositories
 */

import { parseLocalDateKey } from "@daylight/core-calendar";
import { parseDiaryInput } from "@daylight/domain";
import type { DateMark, HolidaySubscription, LocalDateKey, UserSettings } from "@daylight/domain";
import type { DaylightRepositories } from "@daylight/storage";

const HOLIDAY_COLORS = ["rust", "stone", "olive", "amber", "green"] as const;

export async function saveSelectedMark(
  repositories: DaylightRepositories,
  date: LocalDateKey,
  type: DateMark["type"],
  content: string,
): Promise<void> {
  if (!content.trim()) return;
  const parts = parseLocalDateKey(date);
  const mark = type === "yearly"
    ? { type, month: parts.month, day: parts.day, content }
    : type === "monthly"
      ? { type, day: parts.day, content }
      : { type, date, content };
  await repositories.marks.saveMark(mark);
}

export async function deleteMark(repositories: DaylightRepositories, mark: DateMark): Promise<void> {
  await repositories.marks.deleteMark(mark);
}

export async function appendDiaryThought(repositories: DaylightRepositories, date: LocalDateKey, content: string): Promise<void> {
  const parsed = parseDiaryInput(content);
  if (!parsed) return;
  await repositories.diary.addThought(date, parsed.content, parsed.done);
}

export async function toggleDiaryThought(repositories: DaylightRepositories, id: string): Promise<void> {
  await repositories.diary.toggleThought(id);
}

export async function deleteDiaryThought(repositories: DaylightRepositories, id: string): Promise<void> {
  await repositories.diary.deleteThought(id);
}

export async function saveSettings(repositories: DaylightRepositories, settings: UserSettings): Promise<void> {
  await repositories.settings.saveSettings(settings);
}

export async function toggleHolidaySource(
  repositories: DaylightRepositories,
  settings: UserSettings,
  sourceId: string,
): Promise<void> {
  const existing = settings.holidaySubscriptions.find((item) => item.sourceId === sourceId && item.enabled);
  if (existing) await repositories.holidays.removeDaysForSubscription(existing.id);
  const next = existing
    ? settings.holidaySubscriptions.filter((item) => item.id !== existing.id)
    : [...settings.holidaySubscriptions, createHolidaySubscription(sourceId)];
  await repositories.holidays.saveSubscriptions(next);
}

export async function cycleHolidayColor(
  repositories: DaylightRepositories,
  settings: UserSettings,
  subscriptionId: string,
): Promise<void> {
  const next = settings.holidaySubscriptions.map((subscription) => {
    if (subscription.id !== subscriptionId) return subscription;
    const index = HOLIDAY_COLORS.indexOf(subscription.colorId);
    return { ...subscription, colorId: HOLIDAY_COLORS[((index < 0 ? 0 : index) + 1) % HOLIDAY_COLORS.length] ?? "rust" };
  });
  await repositories.holidays.saveSubscriptions(next);
}

export async function updateCustomHoliday(
  repositories: DaylightRepositories,
  settings: UserSettings,
  patch: { readonly name?: string; readonly customURL?: string },
): Promise<void> {
  const next = settings.holidaySubscriptions.map((subscription) => {
    return subscription.sourceId === "custom" && subscription.enabled ? { ...subscription, ...patch } : subscription;
  });
  await repositories.holidays.saveSubscriptions(next);
}

export async function saveHolidayUpdateWeekly(
  repositories: DaylightRepositories,
  settings: UserSettings,
  holidayUpdateWeekly: boolean,
): Promise<void> {
  await repositories.settings.saveSettings({ ...settings, holidayUpdateWeekly });
}

function createHolidaySubscription(sourceId: string): HolidaySubscription {
  return { id: createId(), sourceId, customURL: "", colorId: "rust", enabled: true, name: "" };
}

function createId(): string {
  return globalThis.crypto?.randomUUID?.() ?? `holiday-${Date.now()}-${Math.random().toString(16).slice(2)}`;
}
