/**
 * Public barrel for storage contracts and default adapters.
 * Exports: repository interfaces and in-memory repository factory
 * Deps: package-local storage modules
 */

export { createMemoryRepositories } from "./memory-repositories";
export type { MemoryRepositorySeed } from "./memory-repositories";

export type {
  DaylightRepositories,
  DiaryRepository,
  HolidayRepository,
  MarksRepository,
  PublicCalendarRepository,
  SettingsRepository,
} from "./repositories";
