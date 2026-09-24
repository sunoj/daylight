/**
 * Quick diary save control tests.
 * Covers: save stays disabled for empty or whitespace-only content
 * Deps: node assert, quick diary helper
 */

import assert from "node:assert/strict";
import { canSaveQuickDiary } from "../src/quick-diary";

assert.equal(canSaveQuickDiary(""), false);
assert.equal(canSaveQuickDiary("   "), false);
assert.equal(canSaveQuickDiary("\n\t"), false);
assert.equal(canSaveQuickDiary("[]"), false);
assert.equal(canSaveQuickDiary("[ ]"), false);
assert.equal(canSaveQuickDiary("hello"), true);
assert.equal(canSaveQuickDiary("  note  "), true);
assert.equal(canSaveQuickDiary("[ ] buy milk"), true);
