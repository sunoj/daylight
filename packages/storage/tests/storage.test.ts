/**
 * Storage smoke tests for repository contracts.
 * Covers: settings, marks, diary, and public calendar memory repositories
 * Deps: node assert, storage public API
 */

import assert from "node:assert/strict";
import { createMemoryRepositories } from "../src/index";
import type { DateMark, LocalDateKey } from "@daylight/domain";

const repos = createMemoryRepositories();
const settings = await repos.settings.getSettings();
assert.equal(settings.ok, true);

const date = "2024-02-10" as LocalDateKey;
const mark: DateMark = { type: "oneTime", date, content: "Spring Festival" };
assert.equal((await repos.marks.saveMark(mark)).ok, true);

const marks = await repos.marks.listMarksForDate(date);
assert.equal(marks.ok, true);
if (marks.ok) assert.equal(marks.value.length, 1);

assert.equal((await repos.diary.addThought(date, "New year")).ok, true);
const storedDiary = await repos.diary.listThoughtsForDate(date);
assert.equal(storedDiary.ok, true);
if (storedDiary.ok) assert.equal(storedDiary.value[0]?.content, "New year");

const publicDay = { date, type: "holiday" as const, name: "Spring Festival", isImportant: true };
assert.equal((await repos.publicCalendar.replacePublicDays([publicDay])).ok, true);
const publicDays = await repos.publicCalendar.listPublicDays();
assert.equal(publicDays.ok, true);
if (publicDays.ok) assert.equal(publicDays.value.length, 1);

const deleteRepos = createMemoryRepositories();
assert.equal((await deleteRepos.diary.addThought(date, "keep")).ok, true);
const removable = await deleteRepos.diary.addThought(date, "remove");
assert.equal(removable.ok, true);
if (removable.ok) {
  assert.equal((await deleteRepos.diary.deleteThought(removable.value.id)).ok, true);
  const remaining = await deleteRepos.diary.listThoughtsForDate(date);
  assert.equal(remaining.ok, true);
  if (remaining.ok) {
    assert.equal(remaining.value.length, 1);
    assert.equal(remaining.value[0]?.content, "keep");
  }
}
