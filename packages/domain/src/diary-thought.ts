/**
 * Diary thought model helpers shared by all Daylight clients.
 * Exports: DiaryThought, decode helpers, id and timestamp factories
 * Deps: date primitives
 */

import type { LocalDateKey } from "./date";

export interface DiaryThought {
  readonly id: string;
  readonly date: LocalDateKey;
  readonly content: string;
  readonly createdAt: string;
  readonly updatedAt: string;
  /** Absent for plain notes; false for open todos; true for completed todos. */
  readonly done?: boolean;
}

export interface LegacyDiaryEntry {
  readonly date: LocalDateKey;
  readonly content: string;
  readonly updatedAt: string;
}

export function diaryThoughtTimestamp(date: Date = new Date()): string {
  return date.toISOString();
}

export function createDiaryThoughtId(): string {
  // Narrowed locally rather than pulling the DOM lib into this package: domain
  // stays environment-agnostic, and crypto is optional at runtime anyway.
  const host = globalThis as { crypto?: { randomUUID?: () => string } };
  return host.crypto?.randomUUID?.() ?? `thought-${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

export function legacyDiaryThoughtId(date: LocalDateKey): string {
  return `legacy-${date}`;
}

export function decodeDiaryThought(value: unknown): DiaryThought | null {
  if (!isRecord(value) || typeof value.date !== "string" || typeof value.content !== "string") return null;
  const updatedAt = typeof value.updatedAt === "string" ? value.updatedAt : diaryThoughtTimestamp();
  const done = typeof value.done === "boolean" ? value.done : undefined;
  if (typeof value.id === "string" && typeof value.createdAt === "string") {
    return {
      id: value.id,
      date: value.date as LocalDateKey,
      content: value.content,
      createdAt: value.createdAt,
      updatedAt,
      ...(done === undefined ? {} : { done }),
    };
  }
  return done === undefined
    ? migrateLegacyDiaryEntry({
        date: value.date as LocalDateKey,
        content: value.content,
        updatedAt,
      })
    : {
        ...migrateLegacyDiaryEntry({
          date: value.date as LocalDateKey,
          content: value.content,
          updatedAt,
        }),
        done,
      };
}

export function decodeDiaryThoughts(value: unknown): readonly DiaryThought[] {
  if (!Array.isArray(value)) return [];
  return value.map(decodeDiaryThought).filter((item): item is DiaryThought => item !== null);
}

export function migrateLegacyDiaryEntry(entry: LegacyDiaryEntry): DiaryThought {
  return {
    id: legacyDiaryThoughtId(entry.date),
    date: entry.date,
    content: entry.content,
    createdAt: entry.updatedAt,
    updatedAt: entry.updatedAt,
  };
}

export function createDiaryThought(
  date: LocalDateKey,
  content: string,
  doneOrNow?: boolean | Date,
  now: Date = new Date(),
): DiaryThought {
  const done = doneOrNow instanceof Date ? undefined : doneOrNow;
  const timestampDate = doneOrNow instanceof Date ? doneOrNow : now;
  const timestamp = diaryThoughtTimestamp(timestampDate);
  return {
    id: createDiaryThoughtId(),
    date,
    content,
    createdAt: timestamp,
    updatedAt: timestamp,
    ...(done === undefined ? {} : { done }),
  };
}

const TODO_MARKERS: readonly { readonly prefix: string; readonly done: boolean }[] = [
  { prefix: "[]", done: false },
  { prefix: "[ ]", done: false },
  { prefix: "[x]", done: true },
  { prefix: "[X]", done: true },
];

export function parseDiaryInput(raw: string): { readonly content: string; readonly done?: boolean } | null {
  const input = raw.trim();
  if (!input) return null;
  for (const marker of TODO_MARKERS) {
    if (!input.startsWith(marker.prefix)) continue;
    const content = input.slice(marker.prefix.length).trim();
    if (!content) return null;
    return { content, done: marker.done };
  }
  return { content: input };
}

function compareDiaryThoughtsNewestFirst(left: DiaryThought, right: DiaryThought): number {
  if (left.createdAt === right.createdAt) return right.id.localeCompare(left.id);
  return right.createdAt.localeCompare(left.createdAt);
}

function compareDiaryThoughtsOldestFirst(left: DiaryThought, right: DiaryThought): number {
  if (left.createdAt === right.createdAt) return left.id.localeCompare(right.id);
  return left.createdAt.localeCompare(right.createdAt);
}

export function sortDiaryThoughtsNewestFirst(thoughts: readonly DiaryThought[]): readonly DiaryThought[] {
  return [...thoughts].sort(compareDiaryThoughtsNewestFirst);
}

export function sortDiaryThoughtsOldestFirst(thoughts: readonly DiaryThought[]): readonly DiaryThought[] {
  return [...thoughts].sort(compareDiaryThoughtsOldestFirst);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
