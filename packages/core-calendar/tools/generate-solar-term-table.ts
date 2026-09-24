/**
 * Generates the packed solar-term day table (1949–2100) embedded in
 * src/solar-term-table.ts and the Swift copy in LunarCalendar.swift.
 * Term instants are apparent solar longitude crossings (multiples of 15°)
 * computed with the vendored astronomy-engine and read in UTC+8, matching
 * the official Chinese calendar definition (GB/T 33661-2017). The output
 * was cross-validated against lunar-javascript (寿星天文历 ephemeris):
 * both sources agree on all 3648 term dates in this range.
 *
 * Run: npx tsx --tsconfig packages/core-calendar/tsconfig.json packages/core-calendar/tools/generate-solar-term-table.ts
 */

import { createRequire } from "node:module";

const require2 = createRequire(import.meta.url);
const Astronomy = require2("../../../src/lib/Astronomy.js");

const MS_PER_DAY = 86_400_000;
const START_YEAR = 1949;
const END_YEAR = 2100;

const days: number[][] = []; // [yearIndex][termIndex]
for (let year = START_YEAR; year <= END_YEAR; year += 1) {
  const row: number[] = [];
  for (let index = 0; index < 24; index += 1) {
    const month = Math.floor(index / 2) + 1;
    const targetLon = (285 + 15 * index) % 360;
    const start = new Date(Date.UTC(year, month - 1, 1) - 3 * MS_PER_DAY);
    const t = Astronomy.SearchSunLongitude(targetLon, start, 40);
    if (!t) throw new Error(`No crossing for ${year} term ${index}`);
    const cst = new Date(t.date.getTime() + 8 * 3_600_000);
    if (cst.getUTCMonth() + 1 !== month || cst.getUTCFullYear() !== year) {
      throw new Error(`Term ${year}/${index} outside expected month: ${cst.toISOString()}`);
    }
    row.push(cst.getUTCDate());
  }
  days.push(row);
}

const baseDays: number[] = [];
for (let index = 0; index < 24; index += 1) {
  baseDays.push(Math.min(...days.map((row) => row[index]!)));
  const spread = Math.max(...days.map((row) => row[index]!)) - baseDays[index]!;
  if (spread > 9) throw new Error(`Term ${index} spread ${spread} exceeds single digit`);
}

const packed = days.map((row) => row.map((d, i) => String(d - baseDays[i]!)).join(""));

console.log("// TS ---------------------------------------------------------");
console.log(`export const SOLAR_TERM_TABLE_START_YEAR = ${START_YEAR};`);
console.log(`export const SOLAR_TERM_TABLE_END_YEAR = ${END_YEAR};`);
console.log(`export const SOLAR_TERM_BASE_DAYS = [${baseDays.join(", ")}] as const;`);
console.log("export const SOLAR_TERM_TABLE: readonly string[] = [");
for (let i = 0; i < packed.length; i += 4) {
  const chunk = packed.slice(i, i + 4).map((s) => `"${s}"`).join(", ");
  console.log(`  ${chunk}, // ${START_YEAR + i}–${Math.min(START_YEAR + i + 3, END_YEAR)}`);
}
console.log("];");

console.log("\n// Swift ------------------------------------------------------");
console.log(`    private let termTableStartYear = ${START_YEAR}`);
console.log(`    private let termTableEndYear = ${END_YEAR}`);
console.log(`    private let termBaseDays = [${baseDays.join(", ")}]`);
console.log("    private let termTable = [");
for (let i = 0; i < packed.length; i += 4) {
  const chunk = packed.slice(i, i + 4).map((s) => `"${s}"`).join(", ");
  console.log(`        ${chunk}, // ${START_YEAR + i}–${Math.min(START_YEAR + i + 3, END_YEAR)}`);
}
console.log("    ]");
