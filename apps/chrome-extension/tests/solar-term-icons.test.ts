/**
 * Solar-term icon module tests.
 * Covers: supported term coverage, unknown fallback, unique per-term SVGs
 * Deps: node assert, solar-term icon module
 */

import assert from "node:assert/strict";
import { solarTermIconSvg, solarTermIconTerms } from "../src/solar-term-icons.ts";

const terms = [
  "小寒", "大寒", "立春", "雨水", "惊蛰", "春分", "清明", "谷雨",
  "立夏", "小满", "芒种", "夏至", "小暑", "大暑", "立秋", "处暑",
  "白露", "秋分", "寒露", "霜降", "立冬", "小雪", "大雪", "冬至",
] as const;

assert.deepEqual([...solarTermIconTerms], [...terms]);

const svgs = terms.map((term) => solarTermIconSvg(term));
for (const svg of svgs) {
  assert.match(svg, /^<svg\b/);
  assert.match(svg, /currentColor/);
  assert.doesNotMatch(svg, /#[0-9a-f]/i);
  assert.doesNotMatch(svg, /rgb/i);
}

assert.equal(solarTermIconSvg(""), "");
assert.equal(solarTermIconSvg("not a solar term"), "");
assert.equal(new Set(svgs).size, terms.length);

// The detailed master must contain real additional geometry, not just a larger viewport.
for (const term of terms) {
  const small = solarTermIconSvg(term, 48, "small");
  const large = solarTermIconSvg(term, 48, "large");
  const geometry = (svg: string) => [...svg.matchAll(/ d="([^"]+)"/g)].map(match => match[1]);
  assert.notDeepEqual(geometry(small), geometry(large), term);
  const colors = new Set([...large.matchAll(/(?:fill|stroke)="([^"]+)"/g)]
    .map(match => match[1]).filter(color => color !== "none"));
  assert.ok(colors.size <= 3, `${term} must use at most three inks`);
  assert.doesNotMatch(large, /undefined|NaN/);
  assert.equal(solarTermIconSvg(term, 48), large);
  assert.equal(solarTermIconSvg(` ${term} `), solarTermIconSvg(term));
}
assert.equal(solarTermIconSvg("toString"), "");
assert.equal(solarTermIconSvg("__proto__"), "");

assert.match(solarTermIconSvg("雨水", 48), /--solar-term-cool/);
assert.doesNotMatch(solarTermIconSvg("雨水", 20), /--solar-term-/);
