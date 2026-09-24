/**
 * Calendar grid day-cell subtitle selection.
 * Exports: DayCellSubtitle, getDayCellSubtitle
 * Deps: domain calendar types
 */

import type { LunarDate, PublicCalendarDay, SolarTermName } from "@daylight/domain";

export interface DayCellSubtitle {
  readonly text: string;
  readonly isSolarTerm: boolean;
}

export function getDayCellSubtitle(
  publicDay: PublicCalendarDay | undefined,
  lunarDate: LunarDate | undefined,
  showLunarDate: boolean,
  solarTermLabel: (term: SolarTermName) => string,
): DayCellSubtitle | undefined {
  const publicName = publicDay?.name?.trim();
  if (publicName) return { text: publicName, isSolarTerm: false };
  if (!showLunarDate || !lunarDate) return undefined;
  if (lunarDate.solarTerm) {
    return { text: solarTermLabel(lunarDate.solarTerm), isSolarTerm: true };
  }
  return { text: lunarDate.dayName, isSolarTerm: false };
}
