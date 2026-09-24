/**
 * Holiday detail entry helpers shared by popup summary and detail page.
 * Exports: getHolidayDetailEntries, holidaySourceName
 * Deps: domain types, sync holiday sources
 */

import { holidaySource } from "@daylight/sync";
import type { HolidayDetailEntry, HolidayHit, HolidaySubscription, LocalDateKey, PublicCalendarDay } from "@daylight/domain";
import { t } from "./locale";

export function getHolidayDetailEntries(
  date: LocalDateKey,
  hits: readonly HolidayHit[],
  publicDays: readonly PublicCalendarDay[],
  subscriptions: readonly HolidaySubscription[],
): readonly HolidayDetailEntry[] {
  const subscriptionEntries: HolidayDetailEntry[] = hits
    .filter((hit) => hit.day.date === date)
    .map((hit) => ({
      day: hit.day,
      colorId: hit.subscription.colorId,
      sourceId: hit.subscription.sourceId,
      sourceName: holidaySourceName(hit.subscription),
      isRemote: false,
    }));
  const subscriptionNames = new Set(subscriptionEntries.map((entry) => normalizedName(entry.day.name)).filter(Boolean));
  const remote = publicDays.filter((day) => day.date === date && !subscriptionNames.has(normalizedName(day.name)));
  return subscriptionEntries.concat(remote.map((day): HolidayDetailEntry => ({ day, sourceName: "同步", isRemote: true })));
}

export function holidaySourceName(subscription: HolidaySubscription): string {
  if (subscription.sourceId === "custom") return subscription.name.trim() || t("自定义 iCal 链接");
  return holidaySource(subscription.sourceId)?.name ?? subscription.sourceId;
}

function normalizedName(name: string | undefined): string {
  return name?.trim() ?? "";
}
