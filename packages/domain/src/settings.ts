/**
 * Shared user settings and shell configuration models.
 * Exports: UserSettings, ActionIconMode, ColorScheme, Language
 * Deps: calendar types
 */

import type { CalendarType } from "./calendar";
import type { HolidaySubscription } from "./holidays";

export type ColorScheme = "system" | "light" | "dark";
export type ActionIconMode = "date" | "emoji" | "moonPhase";
export type Language = "zh" | "zh-Hant" | "en" | "th";

export interface UserSettings {
  readonly language: Language;
  readonly colorScheme: ColorScheme;
  readonly showLunarDate: boolean;
  readonly autoOpenTodayDetail: boolean;
  readonly actionIconMode: ActionIconMode;
  readonly showWeekNumbers: boolean;
  readonly calendarType: CalendarType;
  readonly holidaySubscriptions: readonly HolidaySubscription[];
  readonly holidayUpdateWeekly: boolean;
}

export const DEFAULT_USER_SETTINGS: UserSettings = {
  language: "en",
  colorScheme: "system",
  showLunarDate: true,
  autoOpenTodayDetail: false,
  actionIconMode: "date",
  showWeekNumbers: true,
  calendarType: "iso8601",
  holidaySubscriptions: [],
  holidayUpdateWeekly: false,
};
