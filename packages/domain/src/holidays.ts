/**
 * Holiday subscription domain models shared by Daylight clients.
 * Exports: HolidayColorId, HolidaySubscription, HolidayHit
 * Deps: calendar public-day and date primitives
 */

import type { PublicCalendarDay } from "./calendar";

export type HolidayColorId = "rust" | "stone" | "olive" | "amber" | "green";

export interface HolidaySubscription {
  readonly id: string;
  readonly sourceId: string;
  readonly customURL: string;
  readonly colorId: HolidayColorId;
  readonly enabled: boolean;
  readonly name: string;
}

export interface HolidayHit {
  readonly subscription: HolidaySubscription;
  readonly day: PublicCalendarDay;
}

export type HolidayDaysBySubscription = Readonly<Record<string, readonly PublicCalendarDay[]>>;

export interface HolidayDetailEntry {
  readonly day: PublicCalendarDay;
  readonly colorId?: HolidayColorId;
  readonly sourceId?: string;
  readonly sourceName: string;
  readonly isRemote: boolean;
}
