/**
 * Diary repository toggle behavior tests.
 * Covers: toggling a todo flips only that entry's done flag
 * Deps: node assert, memory repositories
 */

import assert from "node:assert/strict";
import { createDiaryThought } from "@daylight/domain";
import type { LocalDateKey } from "@daylight/domain";
import { createMemoryRepositories } from "../src/index";

const date = "2026-07-24" as LocalDateKey;
const todo = { ...createDiaryThought(date, "Buy milk", false), id: "todo-1" };
const plain = { ...createDiaryThought(date, "Plain note"), id: "plain-1" };
const repos = createMemoryRepositories({ diaryThoughts: [todo, plain] });

await repos.diary.toggleThought("todo-1");
const thoughts = (await repos.diary.listThoughtsForDate(date)).value ?? [];
assert.equal(thoughts.find((item) => item.id === "todo-1")?.done, true);
assert.equal(thoughts.find((item) => item.id === "plain-1")?.done, undefined);

await repos.diary.toggleThought("plain-1");
const unchanged = (await repos.diary.listThoughtsForDate(date)).value ?? [];
assert.equal(unchanged.find((item) => item.id === "plain-1")?.done, undefined);
