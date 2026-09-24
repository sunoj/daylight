/**
 * Calendar constants shared by pure calculation modules.
 * Exports: lunar lookup tables, solar term names, weekday rules
 * Deps: domain calendar types
 */

import type { CalendarType, SolarTermName } from "@daylight/domain";

export const MS_PER_DAY = 86_400_000;
export const LUNAR_BASE_UTC_MS = Date.UTC(1949, 0, 29);

// The widely circulated 1949–2100 table with two corrections verified against
// both astronomy-engine and the 寿星天文历 ephemeris (new moons in UTC+8):
// 1996: 0x055c0 → 0x05ac0 (months 5–8 are 30/29/30/29, e.g. 六月初一 is
// 1996-07-16 and 中秋 八月十五 is 1996-09-27), and 2060: 0x0a2e0 → 0x092e0
// (三月 has 29 days; 四月初一 is 2060-04-30, new moon 18:11 CST).
export const LUNAR_YEAR_DATA: readonly number[] = [
  0x0b557, 0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5b0, 0x14573, 0x052b0,
  0x0a9a8, 0x0e950, 0x06aa0, 0x0aea6, 0x0ab50, 0x04b60, 0x0aae4, 0x0a570,
  0x05260, 0x0f263, 0x0d950, 0x05b57, 0x056a0, 0x096d0, 0x04dd5, 0x04ad0,
  0x0a4d0, 0x0d4d4, 0x0d250, 0x0d558, 0x0b540, 0x0b6a0, 0x195a6, 0x095b0,
  0x049b0, 0x0a974, 0x0a4b0, 0x0b27a, 0x06a50, 0x06d40, 0x0af46, 0x0ab60,
  0x09570, 0x04af5, 0x04970, 0x064b0, 0x074a3, 0x0ea50, 0x06b58, 0x05ac0,
  0x0ab60, 0x096d5, 0x092e0, 0x0c960, 0x0d954, 0x0d4a0, 0x0da50, 0x07552,
  0x056a0, 0x0abb7, 0x025d0, 0x092d0, 0x0cab5, 0x0a950, 0x0b4a0, 0x0baa4,
  0x0ad50, 0x055d9, 0x04ba0, 0x0a5b0, 0x15176, 0x052b0, 0x0a930, 0x07954,
  0x06aa0, 0x0ad50, 0x05b52, 0x04b60, 0x0a6e6, 0x0a4e0, 0x0d260, 0x0ea65,
  0x0d530, 0x05aa0, 0x076a3, 0x096d0, 0x04afb, 0x04ad0, 0x0a4d0, 0x1d0b6,
  0x0d250, 0x0d520, 0x0dd45, 0x0b5a0, 0x056d0, 0x055b2, 0x049b0, 0x0a577,
  0x0a4b0, 0x0aa50, 0x1b255, 0x06d20, 0x0ada0, 0x14b63, 0x09370, 0x049f8,
  0x04970, 0x064b0, 0x168a6, 0x0ea50, 0x06b20, 0x1a6c4, 0x0aae0, 0x092e0,
  0x0d2e3, 0x0c960, 0x0d557, 0x0d4a0, 0x0da50, 0x05d55, 0x056a0, 0x0a6d0,
  0x055d4, 0x052d0, 0x0a9b8, 0x0a950, 0x0b4a0, 0x0b6a6, 0x0ad50, 0x055a0,
  0x0aba4, 0x0a5b0, 0x052b0, 0x0b273, 0x06930, 0x07337, 0x06aa0, 0x0ad50,
  0x14b55, 0x04b60, 0x0a570, 0x054e4, 0x0d160, 0x0e968, 0x0d520, 0x0daa0,
  0x16aa6, 0x056d0, 0x04ae0, 0x0a9d4, 0x0a2d0, 0x0d150, 0x0f252, 0x0d520,
];

export const LUNAR_MONTH_LABELS = ["正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊"] as const;
export const LUNAR_DAY_DIGITS = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "初", "廿"] as const;
export const HEAVENLY_STEMS = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"] as const;
export const EARTHLY_BRANCHES = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"] as const;

export const SOLAR_TERM_NAMES: readonly SolarTermName[] = [
  "minor-cold", "major-cold", "spring-begins", "rain-water", "insects-awaken",
  "spring-equinox", "clear-and-bright", "grain-rain", "summer-begins", "grain-full",
  "grain-in-ear", "summer-solstice", "minor-heat", "major-heat", "autumn-begins",
  "limit-of-heat", "white-dew", "autumn-equinox", "cold-dew", "frost-descent",
  "winter-begins", "minor-snow", "major-snow", "winter-solstice",
];

export const SOLAR_TERM_LABELS_ZH: Readonly<Record<SolarTermName, string>> = {
  "spring-equinox": "春分", "clear-and-bright": "清明", "grain-rain": "谷雨",
  "summer-begins": "立夏", "grain-full": "小满", "grain-in-ear": "芒种",
  "summer-solstice": "夏至", "minor-heat": "小暑", "major-heat": "大暑",
  "autumn-begins": "立秋", "limit-of-heat": "处暑", "white-dew": "白露",
  "autumn-equinox": "秋分", "cold-dew": "寒露", "frost-descent": "霜降",
  "winter-begins": "立冬", "minor-snow": "小雪", "major-snow": "大雪",
  "winter-solstice": "冬至", "minor-cold": "小寒", "major-cold": "大寒",
  "spring-begins": "立春", "rain-water": "雨水", "insects-awaken": "惊蛰",
};

export const FIRST_WEEKDAY_BY_CALENDAR: Readonly<Record<CalendarType, 0 | 1 | 6>> = {
  iso8601: 1,
  us: 0,
  arabic: 6,
  hebrew: 0,
};
