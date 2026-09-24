/**
 * Date detail card tests.
 * Covers: solar-term lookup, moon limb derivation, moon disc SVG variance
 * Deps: node assert, Chrome extension detail card helpers
 */

import assert from "node:assert/strict";
import type { LocalDateKey } from "@daylight/domain";
import { getMoonLimb, getSolarTermCardData, moonDiscSvg } from "../src/detail-cards";

assert.equal(getSolarTermCardData("2024-02-04" as LocalDateKey)?.label, "立春");
assert.equal(getSolarTermCardData("2024-02-05" as LocalDateKey), undefined);

assert.equal(getMoonLimb("waxing-crescent"), "right");
assert.equal(getMoonLimb("first-quarter"), "right");
assert.equal(getMoonLimb("waxing-gibbous"), "right");
assert.equal(getMoonLimb("waning-gibbous"), "left");
assert.equal(getMoonLimb("last-quarter"), "left");
assert.equal(getMoonLimb("waning-crescent"), "left");
assert.equal(getMoonLimb("new"), "none");
assert.equal(getMoonLimb("full"), "none");

const newMoon = moonDiscSvg(0, "none");
const halfMoon = moonDiscSvg(0.5, "right");
const fullMoon = moonDiscSvg(1, "none");

assert.equal(moonDiscSvg(0.01, "none"), newMoon);
assert.equal(moonDiscSvg(0.99, "none"), fullMoon);
assert.notEqual(newMoon, halfMoon);
assert.notEqual(halfMoon, fullMoon);
assert.notEqual(newMoon, fullMoon);
assert.match(halfMoon, /A 19 19 0 0 1 20 39 A 0\.0001 19 0 0 1 20 1/);
assert.match(moonDiscSvg(0.25, "left"), /A 19 19 0 0 0 20 39 A 9\.5 19 0 0 1 20 1/);
