/**
 * Chrome extension localization and settings parser tests.
 * Covers: source-string lookup, browser language mapping, settings language migration
 * Deps: node assert, Chrome extension locale/parser modules
 */

import assert from "node:assert/strict";
import { formatCalendarYear, languageFromLocale, setLanguage, t } from "../src/locale";
import { parseSettings } from "../src/chrome-repositories";

setLanguage("zh");
assert.equal(t("今天"), "今天");

setLanguage("zh-Hant");
assert.equal(t("昼间日历"), "晝間日曆");
assert.equal(t("农历与二十四节气"), "農曆與二十四節氣");
assert.equal(t("国庆节（调休上班）"), "國慶節（調休上班）");
assert.equal(t("丑年干支"), "丑年干支");

setLanguage("en");
assert.equal(t("今天"), "Today");
assert.equal(t("满月"), "Full moon");
assert.equal(t("{percent}% 照亮").replace("{percent}", "51"), "51% illuminated");
assert.equal(t("缺少翻译"), "缺少翻译");

setLanguage("th");
assert.equal(t("今天"), "วันนี้");
assert.equal(t("二十四节气"), "24 ฤดูกาลย่อย");
assert.equal(t("缺少翻译"), "缺少翻译");

assert.equal(languageFromLocale("zh-CN"), "zh");
assert.equal(languageFromLocale("zh-Hant"), "zh-Hant");
assert.equal(languageFromLocale("zh-TW"), "zh-Hant");
assert.equal(languageFromLocale("zh_HK"), "zh-Hant");
assert.equal(languageFromLocale("th"), "th");
assert.equal(languageFromLocale("en-US"), "en");
assert.equal(languageFromLocale("fr-FR"), "en");
assert.equal(languageFromLocale(undefined), "en");

const validSettings = parseSettings({
  language: "th",
  colorScheme: "dark",
  showLunarDate: false,
  autoOpenTodayDetail: true,
  actionIconMode: "emoji",
  showWeekNumbers: false,
  calendarType: "hebrew",
}, "en");
assert.equal(validSettings.language, "th");
assert.equal(validSettings.showLunarDate, false);
assert.equal(validSettings.autoOpenTodayDetail, true);
assert.equal(validSettings.actionIconMode, "emoji");
assert.equal(validSettings.showWeekNumbers, false);
assert.equal(validSettings.calendarType, "hebrew");

const traditionalSettings = parseSettings({ language: "zh-Hant" }, "en");
assert.equal(traditionalSettings.language, "zh-Hant");

const invalidLanguage = parseSettings({
  language: "ja",
  showLunarDate: false,
}, "zh");
assert.equal(invalidLanguage.language, "zh");
assert.equal(invalidLanguage.showLunarDate, false);

const absentLanguage = parseSettings({ showWeekNumbers: false }, "th");
assert.equal(absentLanguage.language, "th");
assert.equal(absentLanguage.showWeekNumbers, false);

// Thai displays calendar years in the Buddhist Era (CE + 543); other
// languages keep the Gregorian year.
setLanguage("th");
assert.equal(formatCalendarYear(2026), "2569");
setLanguage("en");
assert.equal(formatCalendarYear(2026), "2026");
setLanguage("zh");
assert.equal(formatCalendarYear(2026), "2026");
