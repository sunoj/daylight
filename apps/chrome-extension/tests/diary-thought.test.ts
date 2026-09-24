/**
 * Chrome diary storage migration tests.
 * Covers: legacy payload decode from chrome.storage.local shape
 * Deps: node assert, domain diary helpers
 */

import assert from "node:assert/strict";
import { decodeDiaryThoughts, legacyDiaryThoughtId } from "@daylight/domain";
import type { LocalDateKey } from "@daylight/domain";

const date = "2024-02-10" as LocalDateKey;
const stored = [
  { date, content: "Legacy", updatedAt: "2024-02-10T08:15:30.000Z" },
  {
    id: "thought-1",
    date,
    content: "New",
    createdAt: "2024-02-11T10:00:00.000Z",
    updatedAt: "2024-02-11T10:00:00.000Z",
  },
];

const thoughts = decodeDiaryThoughts(stored);
assert.equal(thoughts.length, 2);
assert.equal(thoughts[0]?.id, legacyDiaryThoughtId(date));
assert.equal(thoughts[1]?.id, "thought-1");
