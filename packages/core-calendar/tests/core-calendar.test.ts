/**
 * Core calendar smoke tests for the rewritten shared calculation package.
 * Covers: lunar conversion, solar terms, moon phase, grid generation, marks
 * Deps: node assert, core-calendar public API
 */

import assert from "node:assert/strict";
import {
  buildMonthGrid,
  getLunarDate,
  getMarksForDate,
  getMoonAgeDays,
  getMoonPhase,
  getSolarTerm,
  getWeekNumber,
  makeLocalDateKey,
  resolvePublicDay,
} from "../src/index";
import type { DateMark, LocalDateKey } from "@daylight/domain";

const springFestival2024 = getLunarDate("2024-02-10" as LocalDateKey);
assert.equal(springFestival2024.ok, true);
if (springFestival2024.ok) {
  assert.equal(springFestival2024.value.monthName, "正");
  assert.equal(springFestival2024.value.dayName, "初一");
}

assert.equal(getSolarTerm("2024-02-04" as LocalDateKey), "spring-begins");

// Solar terms come from the generated ephemeris table (UTC+8 instants); these
// dates are exactly the years the old linear formula got wrong or that sit at
// the table edges. Golden values cross-checked against 寿星天文历.
assert.equal(getSolarTerm("2026-02-18" as LocalDateKey), "rain-water");
assert.equal(getSolarTerm("2026-02-19" as LocalDateKey), undefined);
assert.equal(getSolarTerm("1950-04-20" as LocalDateKey), "grain-rain");
assert.equal(getSolarTerm("2000-01-06" as LocalDateKey), "minor-cold");
assert.equal(getSolarTerm("2100-03-20" as LocalDateKey), "spring-equinox");
assert.equal(getSolarTerm("2100-12-22" as LocalDateKey), "winter-solstice");
// Outside the table years the approximate fallback still answers.
assert.equal(typeof getSolarTerm("2101-01-05" as LocalDateKey), "string");

// Leap months keep the 闰 prefix and the correct month number.
const leapMonthStart2025 = getLunarDate("2025-07-25" as LocalDateKey);
assert.equal(leapMonthStart2025.ok, true);
if (leapMonthStart2025.ok) {
  assert.equal(leapMonthStart2025.value.monthName, "闰六");
  assert.equal(leapMonthStart2025.value.dayName, "初一");
  assert.equal(leapMonthStart2025.value.yearName, "乙巳");
}
const leapMonth1987 = getLunarDate("1987-08-01" as LocalDateKey);
assert.equal(leapMonth1987.ok, true);
if (leapMonth1987.ok) {
  assert.equal(leapMonth1987.value.monthName, "闰六");
  assert.equal(leapMonth1987.value.dayName, "初七");
}
const leapMonth2023 = getLunarDate("2023-03-22" as LocalDateKey);
assert.equal(leapMonth2023.ok, true);
if (leapMonth2023.ok) {
  assert.equal(leapMonth2023.value.monthName, "闰二");
  assert.equal(leapMonth2023.value.dayName, "初一");
}

// Corrected LUNAR_YEAR_DATA entries: 1996 (六月初一 = 07-16, 中秋 = 09-27) and
// 2060 (四月初一 = 04-30, new moon 18:11 CST).
const lunar19960716 = getLunarDate("1996-07-16" as LocalDateKey);
assert.equal(lunar19960716.ok && `${lunar19960716.value.monthName}${lunar19960716.value.dayName}`, "六初一");
const midAutumn1996 = getLunarDate("1996-09-27" as LocalDateKey);
assert.equal(midAutumn1996.ok && `${midAutumn1996.value.monthName}${midAutumn1996.value.dayName}`, "八十五");
const lunar20600430 = getLunarDate("2060-04-30" as LocalDateKey);
assert.equal(lunar20600430.ok && `${lunar20600430.value.monthName}${lunar20600430.value.dayName}`, "四初一");

// New-moon boundaries where ICU is wrong but the table matches both the
// astronomical instant and the published calendar (e.g. 1954 春节 = 02-03).
const springFestival1954 = getLunarDate("1954-02-03" as LocalDateKey);
assert.equal(springFestival1954.ok && `${springFestival1954.value.monthName}${springFestival1954.value.dayName}`, "正初一");
const springFestival2027 = getLunarDate("2027-02-06" as LocalDateKey);
assert.equal(springFestival2027.ok && `${springFestival2027.value.monthName}${springFestival2027.value.dayName}`, "正初一");

// Range edges: the table starts at lunar new year 1949 and ends with 2100.
const tableStart = getLunarDate("1949-01-29" as LocalDateKey);
assert.equal(tableStart.ok && `${tableStart.value.monthName}${tableStart.value.dayName}`, "正初一");
assert.equal(getLunarDate("1949-01-28" as LocalDateKey).ok, false);
const tableEnd = getLunarDate("2100-12-31" as LocalDateKey);
assert.equal(tableEnd.ok && `${tableEnd.value.yearName}年${tableEnd.value.monthName}${tableEnd.value.dayName}`, "庚申年腊初一");

const fullMoon = getMoonPhase("2024-01-26" as LocalDateKey);
assert.equal(fullMoon.name, "full");
assert.ok(fullMoon.illumination > 0.9);

const today = makeLocalDateKey(2024, 2, 10);
const grid = buildMonthGrid({
  year: 2024,
  month: 2,
  today,
  calendarType: "iso8601",
  showLunarDate: true,
});
assert.equal(grid.days.length, 42);
assert.equal(grid.days.some((day) => day.date === today && day.isToday), true);

// Week numbers follow each calendar type's week rule and match Foundation's
// Calendar.weekOfYear (verified exhaustively 2019–2032 for all four rules).
assert.equal(getWeekNumber("2026-01-01" as LocalDateKey, "iso8601"), 1);
assert.equal(getWeekNumber("2027-01-01" as LocalDateKey, "iso8601"), 53); // Friday → still ISO week 53 of 2026
assert.equal(getWeekNumber("2024-12-30" as LocalDateKey, "iso8601"), 1); // Monday → ISO week 1 of 2025
assert.equal(getWeekNumber("2026-07-22" as LocalDateKey, "iso8601"), 30);
assert.equal(getWeekNumber("2026-01-04" as LocalDateKey, "us"), 2); // Sunday starts week 2 (week 1 = Dec 28–Jan 3)
assert.equal(getWeekNumber("2026-01-03" as LocalDateKey, "arabic"), 2); // Saturday starts week 2 under the Sat-first rule
assert.equal(getWeekNumber("2026-12-31" as LocalDateKey, "us"), 1); // its week contains 2027-01-01, so week 1 of 2027

const marks: readonly DateMark[] = [
  { type: "yearly", month: 2, day: 10, content: "Yearly" },
  { type: "monthly", day: 10, content: "Monthly" },
  { type: "oneTime", date: today, content: "One time" },
];
assert.equal(getMarksForDate(today, marks).length, 3);

const subscriptionDay = { date: today, type: "holiday" as const, name: "Subscription", isImportant: true };
const remoteDay = { date: today, type: "holiday" as const, name: "Remote", isImportant: true };
assert.equal(resolvePublicDay(today, [{ subscription: { id: "a", sourceId: "cn", customURL: "", colorId: "rust", enabled: true, name: "" }, day: subscriptionDay }], [remoteDay])?.name, "Subscription");
assert.equal(resolvePublicDay(today, [], [remoteDay])?.name, "Remote");

const moonAge = getMoonAgeDays(today);
assert.ok(moonAge >= 0);
assert.ok(moonAge < 29.6);
