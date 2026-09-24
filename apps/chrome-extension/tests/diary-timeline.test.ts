/**
 * Diary timeline display order tests.
 * Covers: newest row nearest the input (oldest-first DOM order)
 * Deps: node assert, domain diary helpers, diary timeline renderer
 */

import assert from "node:assert/strict";
import { createDiaryThought } from "@daylight/domain";
import type { LocalDateKey } from "@daylight/domain";
import { thoughtsForTimelineDisplay } from "../src/diary-timeline";

const date = "2026-07-24" as LocalDateKey;
const older = createDiaryThought(date, "first", new Date("2026-07-24T08:00:00.000Z"));
const newer = createDiaryThought(date, "second", new Date("2026-07-24T12:00:00.000Z"));

const display = thoughtsForTimelineDisplay([newer, older]);
assert.deepEqual(display.map((item) => item.content), ["first", "second"]);
