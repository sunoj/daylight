/**
 * Options page state loading.
 * Exports: OptionsState, loadOptionsState
 * Deps: domain types, storage repositories
 */

import type { HolidayHit, UserSettings } from "@daylight/domain";
import type { DaylightRepositories } from "@daylight/storage";

export interface OptionsState {
  readonly settings: UserSettings;
  readonly holidayHits: readonly HolidayHit[];
  readonly holidayMessage: string;
}

export async function loadOptionsState(
  repositories: DaylightRepositories,
  previous?: Partial<Pick<OptionsState, "holidayMessage">>,
): Promise<OptionsState> {
  const settings = await unwrap(repositories.settings.getSettings());
  const holidayHits = await loadHolidayHits(repositories, settings);
  return {
    settings,
    holidayHits,
    holidayMessage: previous?.holidayMessage ?? "",
  };
}

async function loadHolidayHits(repositories: DaylightRepositories, settings: UserSettings): Promise<readonly HolidayHit[]> {
  const enabled = settings.holidaySubscriptions.filter((item) => item.enabled);
  if (enabled.length === 0) return [];
  const publicDays = await unwrap(repositories.publicCalendar.listPublicDays());
  const dates = [...new Set(publicDays.map((day) => day.date))];
  const results = await Promise.all(dates.map((date) => unwrap(repositories.holidays.holidayHits(date))));
  return results.flat();
}

async function unwrap<T>(promise: Promise<{ readonly ok: true; readonly value: T } | { readonly ok: false }>): Promise<T> {
  const result = await promise;
  if (!result.ok) throw new Error("Repository operation failed.");
  return result.value;
}
