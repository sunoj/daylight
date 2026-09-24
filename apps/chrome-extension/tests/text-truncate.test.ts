/**
 * Cell subtitle truncation tests.
 * Covers: word-boundary truncation for Latin holiday names
 * Deps: node assert, text truncate helper
 */

import assert from "node:assert/strict";
import { truncateCellSubtitle } from "../src/text-truncate";

assert.equal(truncateCellSubtitle("国庆节"), "国庆节");
assert.equal(truncateCellSubtitle("The Passover"), "The Passo…");
assert.equal(truncateCellSubtitle("Chulalongkorn Day"), "Chulalong…");
assert.equal(truncateCellSubtitle("Special Administrative Region Day"), "Special…");
