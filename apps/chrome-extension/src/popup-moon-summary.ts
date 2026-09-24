/**
 * Moon summary row data for the calendar popup.
 * Exports: MoonSummaryData, getMoonSummaryData
 * Deps: core-calendar, detail-cards, locale
 */

import { getLunarDate, getMoonAgeDays, getMoonPhase } from "@daylight/core-calendar";
import type { LocalDateKey } from "@daylight/domain";
import { getMoonLimb, moonDiscSvg } from "./detail-cards";
import { t } from "./locale";

export interface MoonSummaryData {
  readonly title: string;
  readonly detail: string;
  readonly discSvg: string;
}

export function getMoonSummaryData(date: LocalDateKey, showLunarDate: boolean, discSize = 44): MoonSummaryData {
  const moon = getMoonPhase(date);
  const percent = Math.round(moon.illumination * 100);
  const age = getMoonAgeDays(date).toFixed(1);
  const phaseLabel = getMoonPhaseLabel(moon.name);
  const lunarSuffix = getLunarSuffix(date, showLunarDate);
  return {
    title: lunarSuffix ? `${phaseLabel} · ${lunarSuffix}` : phaseLabel,
    detail: t("{percent}% 照亮 · 月龄 {age}d")
      .replace("{percent}", String(percent))
      .replace("{age}", age),
    discSvg: moonDiscSvg(moon.illumination, getMoonLimb(moon.name), discSize),
  };
}

function getLunarSuffix(date: LocalDateKey, showLunarDate: boolean): string | undefined {
  if (!showLunarDate) return undefined;
  const lunar = getLunarDate(date);
  if (!lunar.ok) return undefined;
  return t(`${lunar.value.monthName}月${lunar.value.dayName}`);
}

function getMoonPhaseLabel(phaseName: ReturnType<typeof getMoonPhase>["name"]): string {
  return t({
    "new": "新月",
    "waxing-crescent": "娥眉月",
    "first-quarter": "上弦月",
    "waxing-gibbous": "盈凸月",
    "full": "满月",
    "waning-gibbous": "亏凸月",
    "last-quarter": "下弦月",
    "waning-crescent": "残月",
  }[phaseName]);
}
