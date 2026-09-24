/**
 * Handler types for detail and options extension pages.
 * Exports: DetailHandlers, OptionsHandlers
 * Deps: domain types
 */

import type { DateMark, UserSettings } from "@daylight/domain";

export interface DetailHandlers {
  readonly onSaveMark: (type: DateMark["type"], content: string) => void;
  readonly onDeleteMark: (mark: DateMark) => void;
  readonly onSaveDiary: (content: string) => void;
  readonly onDeleteDiaryThought: (id: string) => void;
  readonly onToggleDiaryThought: (id: string) => void;
}

export interface OptionsHandlers {
  readonly onSaveSettings: (settings: UserSettings) => void;
  readonly onToggleHolidaySource: (sourceId: string) => void;
  readonly onCycleHolidayColor: (subscriptionId: string) => void;
  readonly onUpdateCustomHoliday: (patch: { readonly name?: string; readonly customURL?: string }) => void;
  readonly onSaveHolidayUpdateWeekly: (weekly: boolean) => void;
  readonly onRefreshHolidays: () => void;
}
