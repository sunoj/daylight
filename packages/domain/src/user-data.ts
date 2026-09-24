/**
 * User-owned diary and date mark domain models.
 * Exports: DateMark, DiaryThought, DateMarkType
 * Deps: date primitives, diary thought helpers
 */

import type { LocalDateKey } from "./date";

export type { DiaryThought, LegacyDiaryEntry } from "./diary-thought";
export {
  createDiaryThought,
  createDiaryThoughtId,
  decodeDiaryThought,
  decodeDiaryThoughts,
  diaryThoughtTimestamp,
  legacyDiaryThoughtId,
  migrateLegacyDiaryEntry,
  parseDiaryInput,
  sortDiaryThoughtsNewestFirst,
  sortDiaryThoughtsOldestFirst,
} from "./diary-thought";

export type DateMarkType = "yearly" | "monthly" | "oneTime";

export type DateMark =
  | {
      readonly type: "yearly";
      readonly month: number;
      readonly day: number;
      readonly content: string;
    }
  | {
      readonly type: "monthly";
      readonly day: number;
      readonly content: string;
    }
  | {
      readonly type: "oneTime";
      readonly date: LocalDateKey;
      readonly content: string;
    };

/** @deprecated Use DiaryThought. Kept for migration tests and legacy docs. */
export interface DiaryEntry {
  readonly date: LocalDateKey;
  readonly content: string;
  readonly updatedAt: string;
}

export type DateMarkChange =
  | { readonly action: "create"; readonly mark: DateMark }
  | { readonly action: "update"; readonly previous: DateMark; readonly next: DateMark }
  | { readonly action: "delete"; readonly mark: DateMark };
