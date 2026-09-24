/**
 * Chrome holiday repository tests.
 * Covers: ordered overlapping subscription hits and per-subscription day removal
 * Deps: node assert, Chrome repository with mocked chrome.storage
 */

import assert from "node:assert/strict";
import type { HolidaySubscription, PublicCalendarDay } from "@daylight/domain";

const syncStore = new Map<string, unknown>();
const localStore = new Map<string, unknown>();

globalThis.chrome = {
  storage: {
    sync: storageArea(syncStore),
    local: storageArea(localStore),
  },
  i18n: {
    getUILanguage: () => "en-US",
  },
} as typeof chrome;

const { createChromeRepositories } = await import("../src/chrome-repositories");

const repositories = createChromeRepositories();
const subscriptions: readonly HolidaySubscription[] = [
  { id: "sub-a", sourceId: "cn", customURL: "", colorId: "rust", enabled: true, name: "" },
  { id: "sub-b", sourceId: "th", customURL: "", colorId: "green", enabled: true, name: "" },
];
const dayA: PublicCalendarDay = { date: "2026-01-01", type: "holiday", name: "A", isImportant: true };
const dayB: PublicCalendarDay = { date: "2026-01-01", type: "holiday", name: "B", isImportant: true };

assert.equal((await repositories.holidays.saveSubscriptions(subscriptions)).ok, true);
assert.equal((await repositories.holidays.replaceDaysForSubscription("sub-a", [dayA])).ok, true);
assert.equal((await repositories.holidays.replaceDaysForSubscription("sub-b", [dayB])).ok, true);

const overlapping = await repositories.holidays.holidayHits("2026-01-01");
assert.equal(overlapping.ok, true);
if (!overlapping.ok) throw new Error("holidayHits failed");
assert.deepEqual(overlapping.value.map((hit) => hit.subscription.id), ["sub-a", "sub-b"]);
assert.deepEqual(overlapping.value.map((hit) => hit.day.name), ["A", "B"]);

assert.equal((await repositories.holidays.removeDaysForSubscription("sub-a")).ok, true);
const afterRemove = await repositories.holidays.holidayHits("2026-01-01");
assert.equal(afterRemove.ok, true);
if (!afterRemove.ok) throw new Error("holidayHits failed after remove");
assert.deepEqual(afterRemove.value.map((hit) => hit.subscription.id), ["sub-b"]);

function storageArea(store: Map<string, unknown>): chrome.storage.StorageArea {
  return {
    async get(keys) {
      if (typeof keys === "string") return { [keys]: store.get(keys) };
      if (Array.isArray(keys)) return Object.fromEntries(keys.map((key) => [key, store.get(key)]));
      if (keys && typeof keys === "object") return { ...keys, ...Object.fromEntries([...store.entries()]) };
      return Object.fromEntries([...store.entries()]);
    },
    async set(items) {
      for (const [key, value] of Object.entries(items)) store.set(key, value);
    },
    async remove(keys) {
      for (const key of Array.isArray(keys) ? keys : [keys]) store.delete(key);
    },
  };
}
