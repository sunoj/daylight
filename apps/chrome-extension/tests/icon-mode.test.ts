/**
 * Regression coverage for action icon glyph selection.
 * Exports: none (assertion script)
 * Deps: node assert, icon renderer
 */

import assert from "node:assert/strict";
import { resolveIconGlyph } from "../src/icon-renderer";

// A mode the user picked explicitly must be honoured. The moon glyph was
// previously gated to 20:00-05:00, so picking "Moon icon" in daylight silently
// drew the date icon and the setting looked broken.
assert.equal(resolveIconGlyph("moonPhase"), "moon");
assert.equal(resolveIconGlyph("emoji"), "emoji");
assert.equal(resolveIconGlyph("date"), "date");

console.log("icon-mode tests passed");
