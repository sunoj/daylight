/**
 * Diary thought migration and sort tests.
 * Covers: legacy decode, new-shape round-trip, newest-first sort
 * Deps: node assert, domain diary helpers
 */

import assert from "node:assert/strict";
import {
  createDiaryThought,
  decodeDiaryThought,
  decodeDiaryThoughts,
  legacyDiaryThoughtId,
  migrateLegacyDiaryEntry,
  parseDiaryInput,
  sortDiaryThoughtsNewestFirst,
  sortDiaryThoughtsOldestFirst,
} from "../src/diary-thought.js";
import type { LocalDateKey } from "../src/date.js";

const date = "2024-02-10" as LocalDateKey;

const legacyPayload = {
  date,
  content: "Old note",
  updatedAt: "2024-02-10T08:15:30.000Z",
};

const migrated = decodeDiaryThought(legacyPayload);
assert.ok(migrated);
assert.equal(migrated?.id, legacyDiaryThoughtId(date));
assert.equal(migrated?.content, "Old note");
assert.equal(migrated?.createdAt, "2024-02-10T08:15:30.000Z");
assert.equal(migrated?.updatedAt, "2024-02-10T08:15:30.000Z");

const newThought = createDiaryThought(date, "Fresh", new Date("2024-02-11T10:00:00.000Z"));
const roundTrip = decodeDiaryThought(newThought);
assert.deepEqual(roundTrip, newThought);

const mixed = decodeDiaryThoughts([legacyPayload, newThought]);
assert.equal(mixed.length, 2);
assert.equal(mixed[0]?.id, legacyDiaryThoughtId(date));
assert.equal(mixed[1]?.id, newThought.id);

const ordered = sortDiaryThoughtsNewestFirst([
  createDiaryThought(date, "first", new Date("2026-07-24T08:00:00.000Z")),
  createDiaryThought(date, "second", new Date("2026-07-24T12:00:00.000Z")),
]);
assert.deepEqual(ordered.map((item) => item.content), ["second", "first"]);

assert.deepEqual(migrateLegacyDiaryEntry(legacyPayload).id, legacyDiaryThoughtId(date));

assert.equal(parseDiaryInput(""), null);
assert.equal(parseDiaryInput("   "), null);
assert.equal(parseDiaryInput("[]"), null);
assert.equal(parseDiaryInput("[ ]   "), null);
assert.deepEqual(parseDiaryInput("[] buy milk"), { content: "buy milk", done: false });
assert.deepEqual(parseDiaryInput("[ ] buy milk"), { content: "buy milk", done: false });
assert.deepEqual(parseDiaryInput("[x] buy milk"), { content: "buy milk", done: true });
assert.deepEqual(parseDiaryInput("[X] buy milk"), { content: "buy milk", done: true });
assert.deepEqual(parseDiaryInput("plain note"), { content: "plain note" });
assert.deepEqual(parseDiaryInput("  spaced  "), { content: "spaced" });
assert.deepEqual(parseDiaryInput("note [] marker"), { content: "note [] marker" });

const todoPayload = {
  id: "todo-1",
  date,
  content: "Buy milk",
  createdAt: "2024-02-11T10:00:00.000Z",
  updatedAt: "2024-02-11T10:00:00.000Z",
  done: false,
};
const decodedTodo = decodeDiaryThought(todoPayload);
assert.equal(decodedTodo?.done, false);
assert.equal(decodeDiaryThought(legacyPayload)?.done, undefined);
assert.equal(decodeDiaryThought({ ...newThought, done: true })?.done, true);

const tiedAt = "2026-07-24T08:00:00.000Z";
const tieA = { ...createDiaryThought(date, "a", new Date(tiedAt)), id: "mid-tie" };
const tieB = { ...createDiaryThought(date, "b", new Date(tiedAt)), id: "zzz-tie" };
const tieC = { ...createDiaryThought(date, "c", new Date(tiedAt)), id: "aaa-tie" };
assert.deepEqual(
  sortDiaryThoughtsNewestFirst([tieC, tieA, tieB]).map((item) => item.id),
  ["zzz-tie", "mid-tie", "aaa-tie"],
);
assert.deepEqual(
  sortDiaryThoughtsOldestFirst([tieC, tieA, tieB]).map((item) => item.id),
  ["aaa-tie", "mid-tie", "zzz-tie"],
);
