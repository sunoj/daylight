/**
 * In-memory storage implementation for tests and early app wiring.
 * Exports: createMemoryRepositories
 * Deps: domain types, core-calendar mark helpers, repository contracts
 */

import { createDateMarkKey, getMarksForDate } from "@daylight/core-calendar";
import {
  createDiaryThought,
  decodeDiaryThoughts,
  DEFAULT_USER_SETTINGS,
  diaryThoughtTimestamp,
  ok,
  sortDiaryThoughtsNewestFirst,
} from "@daylight/domain";
import type { DateMark, DiaryThought, LocalDateKey, PublicCalendarDay, UserSettings } from "@daylight/domain";
import type { DaylightRepositories } from "./repositories";

export interface MemoryRepositorySeed {
  readonly settings?: UserSettings;
  readonly marks?: readonly DateMark[];
  readonly diaryThoughts?: readonly DiaryThought[];
  readonly publicDays?: readonly PublicCalendarDay[];
  readonly holidayDaysBySubscription?: Readonly<Record<string, readonly PublicCalendarDay[]>>;
}

export function createMemoryRepositories(seed: MemoryRepositorySeed = {}): DaylightRepositories {
  let settings = seed.settings ?? DEFAULT_USER_SETTINGS;
  const marksByKey = new Map(seed.marks?.map((mark) => [createDateMarkKey(mark), mark]));
  const thoughts = [...(seed.diaryThoughts ?? [])];
  let publicDays = [...(seed.publicDays ?? [])];
  const holidayDaysBySubscription = new Map(Object.entries(seed.holidayDaysBySubscription ?? {}));

  return {
    settings: {
      async getSettings() {
        return ok(settings);
      },
      async saveSettings(nextSettings) {
        settings = nextSettings;
        return ok(settings);
      },
    },
    marks: {
      async listMarks() {
        return ok([...marksByKey.values()]);
      },
      async listMarksForDate(date) {
        return ok(getMarksForDate(date, [...marksByKey.values()]));
      },
      async saveMark(mark) {
        marksByKey.set(createDateMarkKey(mark), mark);
        return ok(mark);
      },
      async deleteMark(mark) {
        marksByKey.delete(createDateMarkKey(mark));
        return ok(undefined);
      },
    },
    diary: {
      async listThoughtsForDate(date: LocalDateKey) {
        return ok(sortDiaryThoughtsNewestFirst(thoughts.filter((item) => item.date === date)));
      },
      async listAllThoughts() {
        return ok([...thoughts].sort((left, right) => left.date.localeCompare(right.date) || left.createdAt.localeCompare(right.createdAt)));
      },
      async addThought(date: LocalDateKey, content: string, done?: boolean) {
        const thought = createDiaryThought(date, content, done);
        thoughts.push(thought);
        return ok(thought);
      },
      async toggleThought(id: string) {
        const index = thoughts.findIndex((item) => item.id === id);
        const current = index >= 0 ? thoughts[index] : undefined;
        if (!current || current.done === undefined) return ok(undefined);
        thoughts[index] = { ...current, done: !current.done, updatedAt: diaryThoughtTimestamp() };
        return ok(undefined);
      },
      async deleteThought(id: string) {
        const index = thoughts.findIndex((item) => item.id === id);
        if (index >= 0) thoughts.splice(index, 1);
        return ok(undefined);
      },
    },
    publicCalendar: {
      async listPublicDays() {
        return ok(publicDays);
      },
      async replacePublicDays(days) {
        publicDays = [...days];
        return ok(publicDays);
      },
    },
    holidays: {
      async listSubscriptions() {
        return ok(settings.holidaySubscriptions);
      },
      async saveSubscriptions(subscriptions) {
        settings = { ...settings, holidaySubscriptions: [...subscriptions] };
        return ok(settings.holidaySubscriptions);
      },
      async replaceDaysForSubscription(subscriptionId, days) {
        holidayDaysBySubscription.set(subscriptionId, [...days]);
        return ok([...days]);
      },
      async removeDaysForSubscription(subscriptionId) {
        holidayDaysBySubscription.delete(subscriptionId);
        return ok(undefined);
      },
      async holidayHits(date) {
        const hits = settings.holidaySubscriptions.filter((item) => item.enabled).flatMap((subscription) => {
          return (holidayDaysBySubscription.get(subscription.id) ?? [])
            .filter((day) => day.date === date)
            .map((day) => ({ subscription, day }));
        });
        return ok(hits);
      },
    },
  };
}
