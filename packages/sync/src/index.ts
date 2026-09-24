/**
 * Public barrel for Daylight remote sync modules.
 * Exports: HTTP client port, public calendar sync, default config parsing
 * Deps: package-local sync modules
 */

export type { HttpClient, JsonResponse } from "./http-client";

export { parsePublicCalendarPayload, syncPublicCalendar } from "./public-calendar-sync";
export type { PublicCalendarSyncInput } from "./public-calendar-sync";

export { parseDefaultConfigPayload } from "./default-config";
export type { DefaultConfig } from "./default-config";

export {
  HOLIDAY_SOURCES,
  holidaySource,
  parseHolidayCalendarName,
  parseHolidayIcs,
  resolvedCustomHolidayName,
  resolvedHolidayUrl,
} from "./holiday-ical";
export type { HolidayFeed, HolidaySource, HolidaySourceCount } from "./holiday-ical";
