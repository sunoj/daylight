/**
 * Diary timeline interaction tests.
 * Covers: todo toggle, two-click delete confirmation
 * Deps: node assert, test DOM shim, diary timeline renderer
 */

import assert from "node:assert/strict";
import { createDiaryThought } from "@daylight/domain";
import type { LocalDateKey } from "@daylight/domain";
import { renderDiaryTimeline } from "../src/diary-timeline";
import { installTestDom } from "./test-dom";

installTestDom();

const date = "2026-07-24" as LocalDateKey;
const todo = { ...createDiaryThought(date, "Buy milk", false), id: "todo-1" };
const plain = createDiaryThought(date, "Plain note");

let toggledId = "";
let deletedIds: string[] = [];

const timeline = renderDiaryTimeline([todo, plain], {
  onToggleThought: (id) => {
    toggledId = id;
  },
  onDeleteThought: (id) => {
    deletedIds.push(id);
  },
});

assert.ok(timeline);
const rows = timeline!.querySelectorAll(".diary-thought");
assert.equal(rows.length, 2);

const todoRow = rows.find((row) => row.querySelector(".diary-thought-toggle"));
const plainRow = rows.find((row) => !row.querySelector(".diary-thought-toggle"));
assert.ok(todoRow);
assert.ok(plainRow);

todoRow!.querySelector(".diary-thought-toggle")!.click();
assert.equal(toggledId, "todo-1");

const firstDelete = plainRow!.querySelector(".diary-thought-delete")!;
const secondDelete = todoRow!.querySelector(".diary-thought-delete")!;

firstDelete.click();
assert.deepEqual(deletedIds, []);
assert.equal(firstDelete.classList.contains("armed"), true);
assert.equal(secondDelete.classList.contains("armed"), false);

secondDelete.click();
assert.deepEqual(deletedIds, []);
assert.equal(firstDelete.classList.contains("armed"), false);
assert.equal(secondDelete.classList.contains("armed"), true);

secondDelete.click();
assert.deepEqual(deletedIds, ["todo-1"]);

toggledId = "";
deletedIds = [];
const rerendered = renderDiaryTimeline([todo], {
  onToggleThought: (id) => {
    toggledId = id;
  },
  onDeleteThought: (id) => {
    deletedIds.push(id);
  },
});
const rerenderDelete = rerendered!.querySelector(".diary-thought-delete")!;
rerenderDelete.click();
assert.equal(rerenderDelete.classList.contains("armed"), true);
rerenderDelete.click();
assert.deepEqual(deletedIds, ["todo-1"]);
