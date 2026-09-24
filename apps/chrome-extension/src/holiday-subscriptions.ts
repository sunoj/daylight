/**
 * Chrome holiday subscription fetch and permission workflow.
 * Exports: refreshHolidaySubscriptions
 * Deps: Chrome permissions, shared iCal parser, storage repositories
 */

import { parseHolidayIcs, resolvedCustomHolidayName, resolvedHolidayUrl } from "@daylight/sync";
import type { HolidaySubscription } from "@daylight/domain";
import type { DaylightRepositories } from "@daylight/storage";

export type HolidayRefreshStatus = "success" | "invalid-url" | "permission-denied" | "empty-feed" | "fetch-failed";

export interface HolidayRefreshResult {
  readonly subscription: HolidaySubscription;
  readonly status: HolidayRefreshStatus;
  readonly count: number;
}

export async function refreshHolidaySubscriptions(
  repositories: DaylightRepositories,
  options: { readonly requestCustomPermissions: boolean },
): Promise<readonly HolidayRefreshResult[]> {
  const listed = await repositories.holidays.listSubscriptions();
  if (!listed.ok) return [];
  const enabled = listed.value.filter((subscription) => subscription.enabled);
  const results = await Promise.all(enabled.map((subscription) => refreshOne(repositories, subscription, options)));
  await persistResolvedSubscriptions(repositories, listed.value, results);
  return orderedResults(enabled, results);
}

async function refreshOne(
  repositories: DaylightRepositories,
  subscription: HolidaySubscription,
  options: { readonly requestCustomPermissions: boolean },
): Promise<HolidayRefreshResult> {
  const url = resolvedHolidayUrl(subscription.sourceId, subscription.customURL);
  if (!url || !isHttpUrl(url)) return failed(subscription, "invalid-url");
  if (subscription.sourceId === "custom" && options.requestCustomPermissions) {
    const granted = await requestHostPermission(url);
    if (!granted) return failed(subscription, "permission-denied");
  }
  try {
    const feed = parseHolidayIcs(await fetchText(url));
    if (feed.days.length === 0) return failed(subscription, "empty-feed");
    const resolved = resolveSubscription(subscription, feed.name, url);
    await repositories.holidays.replaceDaysForSubscription(resolved.id, feed.days);
    return { subscription: resolved, status: "success", count: feed.days.length };
  } catch {
    return failed(subscription, "fetch-failed");
  }
}

function resolveSubscription(subscription: HolidaySubscription, calendarName: string | null, url: string): HolidaySubscription {
  if (subscription.sourceId !== "custom") return subscription;
  return { ...subscription, name: resolvedCustomHolidayName(subscription, calendarName, url) };
}

async function persistResolvedSubscriptions(
  repositories: DaylightRepositories,
  subscriptions: readonly HolidaySubscription[],
  results: readonly HolidayRefreshResult[],
): Promise<void> {
  const next = subscriptions.map((subscription) => {
    return results.find((result) => result.status === "success" && result.subscription.id === subscription.id)?.subscription ?? subscription;
  });
  if (next.some((subscription, index) => subscription !== subscriptions[index])) {
    await repositories.holidays.saveSubscriptions(next);
  }
}

function orderedResults(enabled: readonly HolidaySubscription[], results: readonly HolidayRefreshResult[]): readonly HolidayRefreshResult[] {
  return enabled.map((subscription) => results.find((result) => result.subscription.id === subscription.id))
    .filter((result): result is HolidayRefreshResult => !!result);
}

async function requestHostPermission(url: string): Promise<boolean> {
  const origin = `${new URL(url).origin}/*`;
  if (await chrome.permissions.contains({ origins: [origin] })) return true;
  return chrome.permissions.request({ origins: [origin] });
}

async function fetchText(url: string): Promise<string> {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  return response.text();
}

function failed(subscription: HolidaySubscription, status: HolidayRefreshStatus): HolidayRefreshResult {
  return { subscription, status, count: 0 };
}

function isHttpUrl(url: string): boolean {
  try {
    const parsed = new URL(url);
    return parsed.protocol === "https:" || parsed.protocol === "http:";
  } catch {
    return false;
  }
}
