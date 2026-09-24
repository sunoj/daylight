/** Adjusted workdays remain visible with lunar dates on or off. */
import assert from "node:assert/strict";
import { DEFAULT_USER_SETTINGS } from "@daylight/domain";
import type { LocalDateKey } from "@daylight/domain";
import { renderMonthStack } from "../src/popup-calendar-grid-render";
import type { CalendarHandlers } from "../src/popup-render";
import { CALENDAR_NAVIGATION } from "../src/popup-router";
import { installTestDom } from "./test-dom";
import { setLanguage } from "../src/locale";

installTestDom();
setLanguage("zh-Hant");
const date = "2026-10-10" as LocalDateKey;
let selected: LocalDateKey | undefined;
const handlers = { onSelectDate(value: LocalDateKey) { selected = value; } } as CalendarHandlers;
for (const showLunarDate of [false, true]) {
  const grid = renderMonthStack({
    selectedDate: date, visibleYear: 2026, visibleMonth: 10, viewMode: "month",
    settings: { ...DEFAULT_USER_SETTINGS, showLunarDate },
    marks: [], publicDays: [], diaryThoughts: [], navigation: CALENDAR_NAVIGATION,
    holidayHits: [
      { subscription: { id: "cn", sourceId: "cn", customURL: "", colorId: "rust", enabled: true, name: "" },
        day: { date, type: "workday", name: "国庆节", isImportant: true } },
      { subscription: { id: "cn", sourceId: "cn", customURL: "", colorId: "rust", enabled: true, name: "" },
        day: { date: "2026-10-01" as LocalDateKey, type: "holiday", name: "国庆节", isImportant: true } },
    ],
  }, handlers);
  assert.equal(grid.querySelectorAll(".workday-badge").length, 1);
  const cell = grid.querySelector<HTMLButtonElement>(".workday")!;
  assert.equal(cell.querySelector(".num")?.textContent, "10");
  assert.equal(cell.querySelector(".workday-badge")?.textContent, "班");
  assert.equal(cell.querySelector(".lunar")?.textContent, "國慶節");
  assert.ok(cell.querySelector(".workday-badge")?.getAttribute("aria-label"));
  cell.click();
  assert.equal(selected, date);
}
