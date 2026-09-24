/**
 * Quick diary save eligibility.
 * Exports: canSaveQuickDiary
 * Deps: domain diary input parser
 */

import { parseDiaryInput } from "@daylight/domain";

export function canSaveQuickDiary(content: string): boolean {
  return parseDiaryInput(content) !== null;
}
