/**
 * Public day resolution and day-cell subtitle tests.
 * Covers: subscription precedence over remote public days, solar term emphasis
 * Deps: node assert, core-calendar public API
 */

import assert from "node:assert/strict";
import { getDayCellSubtitle, resolvePublicDay } from "@daylight/core-calendar";
import type { HolidayHit, LocalDateKey, PublicCalendarDay } from "@daylight/domain";

const date = "2026-10-01" as LocalDateKey;
const remoteDay: PublicCalendarDay = { date, type: "holiday", name: "Remote", isImportant: true };
const subscriptionDay: PublicCalendarDay = { date, type: "holiday", name: "国庆节", isImportant: true };
const hit: HolidayHit = {
  subscription: { id: "cn", sourceId: "cn", customURL: "", colorId: "rust", enabled: true, name: "" },
  day: subscriptionDay,
};

assert.equal(resolvePublicDay(date, [hit], [remoteDay])?.name, "国庆节");
assert.equal(resolvePublicDay(date, [], [remoteDay])?.name, "Remote");
assert.equal(resolvePublicDay(date, [], [])?.name, undefined);

const solarTerm = getDayCellSubtitle(undefined, {
  yearName: "乙巳",
  monthName: "九",
  dayName: "廿一",
  solarTerm: "cold-dew",
}, true, () => "寒露");
assert.equal(solarTerm?.text, "寒露");
assert.equal(solarTerm?.isSolarTerm, true);

const holidaySubtitle = getDayCellSubtitle(subscriptionDay, {
  yearName: "乙巳",
  monthName: "九",
  dayName: "廿一",
  solarTerm: "cold-dew",
}, true, () => "寒露");
assert.equal(holidaySubtitle?.text, "国庆节");
assert.equal(holidaySubtitle?.isSolarTerm, false);
