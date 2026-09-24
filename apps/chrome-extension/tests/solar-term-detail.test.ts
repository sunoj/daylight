/** Verify the date-detail renderer selects the large master and clears it on ordinary days. */
import assert from "node:assert/strict";
import { DEFAULT_USER_SETTINGS } from "@daylight/domain";
import type { LocalDateKey } from "@daylight/domain";
import { renderDetail } from "../src/detail-render";
import { solarTermIconSvg } from "../src/solar-term-icons";
import { installTestDom } from "./test-dom";

installTestDom();
const handlers = {
  onSaveMark() {}, onDeleteMark() {}, onSaveDiary() {},
  onDeleteDiaryThought() {}, onToggleDiaryThought() {},
};
function detail(date: string, showLunarDate = true) {
  return renderDetail({
    selectedDate: date as LocalDateKey,
    settings: { ...DEFAULT_USER_SETTINGS, showLunarDate },
    selectedMarks: [], diaryThoughts: [], publicDays: [], holidayHits: [], selectedHolidayEntries: [],
  }, handlers);
}
const spring = detail("2024-02-04");
assert.equal(spring.querySelector(".solar-term-icon")?.innerHTML, solarTermIconSvg("立春", 48, "large"));
assert.ok(spring.querySelector(".moon-disc"));
assert.equal(detail("2024-02-05").querySelectorAll(".solar-term-icon").length, 0);
assert.ok(detail("2024-02-05").querySelector(".moon-disc"));
const lunarDisabled = detail("2024-02-04", false);
assert.equal(lunarDisabled.querySelectorAll(".solar-term-icon").length, 0);
assert.ok(lunarDisabled.querySelector(".moon-disc"));
