/**
 * Calendar period picker arithmetic and lunar label tests.
 * Covers: period titles, grid tiles, zoom navigation, lunar labels
 * Deps: node assert, calendar period module, popup model helpers
 */

import assert from "node:assert/strict";
import {
  addVisibleMonths,
  buildPeriodGridItems,
  calendarPeriod,
  lunarMonthSpan,
  lunarYearName,
  nextViewMode,
} from "../src/calendar-period";
import {
  jumpToToday,
  moveMonth,
  selectPeriod,
  zoomIn,
  zoomOut,
  type PopupState,
} from "../src/popup-model";
import { CALENDAR_NAVIGATION } from "../src/popup-router";
import { setLanguage } from "../src/locale";

const baseState = (): PopupState => ({
  selectedDate: "2026-06-29",
  visibleYear: 2026,
  visibleMonth: 6,
  viewMode: "month",
  settings: {
    language: "zh",
    colorScheme: "system",
    showLunarDate: true,
    autoOpenTodayDetail: false,
    actionIconMode: "emoji",
    showWeekNumbers: false,
    calendarType: "iso8601",
  },
  marks: [],
  publicDays: [],
  holidayHits: [],
  diaryThoughts: [],
  navigation: CALENDAR_NAVIGATION,
});

setLanguage("zh");
assert.equal(calendarPeriod(2026, 6, "month").title, "2026.06");
assert.equal(calendarPeriod(2026, 6, "year").title, "2026");
assert.equal(calendarPeriod(2026, 6, "decade").title, "2020–2029");
assert.equal(calendarPeriod(2026, 6, "century").title, "2000–2099");

setLanguage("th");
assert.equal(calendarPeriod(2026, 6, "month").title, "2569.06");
assert.equal(calendarPeriod(2026, 6, "year").title, "2569");
assert.equal(calendarPeriod(2026, 6, "decade").title, "2563–2572");
assert.equal(calendarPeriod(2026, 6, "century").title, "2543–2642");
setLanguage("zh");

assert.equal(calendarPeriod(2026, 6, "month").nextStepMonths, 1);
assert.equal(calendarPeriod(2026, 6, "year").nextStepMonths, 12);
assert.equal(calendarPeriod(2026, 6, "decade").nextStepMonths, 120);
assert.equal(calendarPeriod(2026, 6, "century").nextStepMonths, 1200);

const yearTiles = buildPeriodGridItems(2026, 6, 2026, 6, "year", true);
assert.equal(yearTiles.length, 12);
assert.equal(yearTiles[5]?.title, "6月");
assert.equal(yearTiles[5]?.isSelected, true);
assert.equal(yearTiles.every((tile) => !tile.isOutsidePeriod), true);

const decadeTiles = buildPeriodGridItems(2029, 7, 2029, 7, "decade", true);
assert.equal(decadeTiles.length, 12);
assert.equal(decadeTiles[0]?.year, 2019);
assert.equal(decadeTiles[0]?.isOutsidePeriod, true);
assert.equal(decadeTiles[1]?.year, 2020);
assert.equal(decadeTiles[1]?.isOutsidePeriod, false);
assert.equal(decadeTiles[10]?.year, 2029);
assert.equal(decadeTiles[10]?.isSelected, true);
assert.equal(decadeTiles[11]?.isOutsidePeriod, true);

const centuryTiles = buildPeriodGridItems(2026, 6, 2026, 6, "century", true);
assert.equal(centuryTiles.length, 12);
assert.equal(centuryTiles[0]?.isOutsidePeriod, true);
assert.equal(centuryTiles[1]?.title, "2000–2009");
assert.equal(centuryTiles[1]?.isOutsidePeriod, false);
assert.equal(centuryTiles[3]?.isSelected, true);
assert.equal(centuryTiles[11]?.isOutsidePeriod, true);

setLanguage("zh");
assert.equal(lunarMonthSpan(2029, 7), "五月–六月");
assert.equal(lunarMonthSpan(2028, 6), "五月–闰五月");
assert.equal(lunarYearName(2029), "己酉年");

let state = baseState();
assert.equal(zoomOut(state).viewMode, "year");
state = { ...state, viewMode: "year" };
assert.equal(zoomOut(state).viewMode, "decade");
state = { ...state, viewMode: "decade" };
assert.equal(zoomOut(state).viewMode, "century");
state = { ...state, viewMode: "century" };
assert.equal(zoomOut(state).viewMode, "century");
assert.equal(nextViewMode("century"), undefined);

state = { ...baseState(), viewMode: "year" };
const picked = selectPeriod(state, 2026, 3, "month");
assert.equal(picked.viewMode, "month");
assert.equal(picked.visibleMonth, 3);
assert.equal(picked.visibleYear, 2026);

state = { ...baseState(), viewMode: "decade", visibleYear: 2020 };
const pickedYear = selectPeriod(state, 2025, 1, "year");
assert.equal(pickedYear.viewMode, "year");
assert.equal(pickedYear.visibleYear, 2025);

state = { ...baseState(), viewMode: "year", visibleYear: 2026, visibleMonth: 6 };
const prevYear = moveMonth(state, -1);
assert.equal(prevYear.visibleYear, 2025);
assert.equal(prevYear.visibleMonth, 6);
const nextDecade = moveMonth({ ...state, viewMode: "decade", visibleYear: 2020 }, 1);
assert.equal(nextDecade.visibleYear, 2030);
const prevCentury = moveMonth({ ...state, viewMode: "century", visibleYear: 2000 }, -1);
assert.equal(prevCentury.visibleYear, 1900);

const withoutLunar = buildPeriodGridItems(2029, 7, 2029, 7, "year", false);
assert.equal(withoutLunar.every((tile) => tile.subtitle === undefined), true);
const withLunar = buildPeriodGridItems(2029, 7, 2029, 7, "year", true);
assert.ok(withLunar.some((tile) => tile.subtitle?.includes("五月")));

assert.equal(jumpToToday().viewMode, "month");
assert.equal(zoomIn({ ...baseState(), viewMode: "decade" }).viewMode, "year");
assert.equal(addVisibleMonths(2026, 6, 12).year, 2027);
