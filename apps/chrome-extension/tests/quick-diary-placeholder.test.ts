/**
 * Date-aware quick diary placeholder tests.
 * Covers: today vs selected-day wording in each language
 * Deps: node assert, locale helpers, quick diary placeholder
 */

import assert from "node:assert/strict";
import type { LocalDateKey } from "@daylight/domain";
import { quickDiaryPlaceholder } from "../src/quick-diary-placeholder";
import { setLanguage } from "../src/locale";

const today = "2026-08-21" as LocalDateKey;
const selected = "2026-08-19" as LocalDateKey;

setLanguage("zh");
assert.equal(quickDiaryPlaceholder(today, today), "记一笔今天…");
assert.equal(quickDiaryPlaceholder(selected, today), "记一笔 8月19日…");

setLanguage("zh-Hant");
assert.equal(quickDiaryPlaceholder(today, today), "記一筆今天…");
assert.equal(quickDiaryPlaceholder(selected, today), "記一筆 8月19日…");

setLanguage("en");
assert.equal(quickDiaryPlaceholder(today, today), "Note today…");
assert.equal(quickDiaryPlaceholder(selected, today), "Note Aug 19…");

setLanguage("th");
assert.equal(quickDiaryPlaceholder(today, today), "บันทึกวันนี้…");
assert.equal(quickDiaryPlaceholder(selected, today), "บันทึก 19 ส.ค.…");
