/**
 * Chrome diary storage read/write with legacy payload migration.
 * Exports: readDiaryThoughts, writeDiaryThoughts
 * Deps: domain diary thought helpers
 */

import { decodeDiaryThoughts } from "@daylight/domain";
import type { DiaryThought } from "@daylight/domain";

const DIARY_KEY = "diaryEntries";

export async function readDiaryThoughts(): Promise<readonly DiaryThought[]> {
  const stored = await chrome.storage.local.get(DIARY_KEY);
  return decodeDiaryThoughts(stored[DIARY_KEY]);
}

export async function writeDiaryThoughts(thoughts: readonly DiaryThought[]): Promise<void> {
  await chrome.storage.local.set({ [DIARY_KEY]: thoughts });
}

export { DIARY_KEY };
