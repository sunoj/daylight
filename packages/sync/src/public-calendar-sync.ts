/**
 * Public calendar sync orchestration for typed remote data.
 * Exports: syncPublicCalendar, parsePublicCalendarPayload
 * Deps: domain types, storage repositories, HTTP client port
 */

import { err, ok } from "@daylight/domain";
import type { PublicCalendarDay, RemoteDataSource, Result } from "@daylight/domain";
import type { PublicCalendarRepository } from "@daylight/storage";
import type { HttpClient } from "./http-client";

export interface PublicCalendarSyncInput {
  readonly source: RemoteDataSource;
  readonly httpClient: HttpClient;
  readonly repository: PublicCalendarRepository;
}

export async function syncPublicCalendar(input: PublicCalendarSyncInput): Promise<Result<readonly PublicCalendarDay[]>> {
  if (input.source.kind !== "public-calendar") {
    return err({ code: "validation-failed", message: "Remote source is not a public calendar source." });
  }

  const response = await input.httpClient.getJson(input.source.url);
  if (!response.ok) return response;
  if (response.value.status < 200 || response.value.status >= 300) {
    return err({ code: "sync-failed", message: `Public calendar request failed with ${response.value.status}.` });
  }

  const parsed = parsePublicCalendarPayload(response.value.body);
  if (!parsed.ok) return parsed;
  return input.repository.replacePublicDays(parsed.value);
}

export function parsePublicCalendarPayload(payload: unknown): Result<readonly PublicCalendarDay[]> {
  if (!Array.isArray(payload)) {
    return err({ code: "validation-failed", message: "Public calendar payload must be an array." });
  }

  const days: PublicCalendarDay[] = [];
  for (const item of payload) {
    const parsed = parsePublicCalendarDay(item);
    if (!parsed.ok) return parsed;
    days.push(parsed.value);
  }
  return ok(days);
}

function parsePublicCalendarDay(item: unknown): Result<PublicCalendarDay> {
  if (!isRecord(item)) {
    return err({ code: "validation-failed", message: "Public calendar item must be an object." });
  }
  if (typeof item.date !== "string" || typeof item.type !== "string") {
    return err({ code: "validation-failed", message: "Public calendar item requires date and type." });
  }
  if (!["holiday", "workday", "observance"].includes(item.type)) {
    return err({ code: "validation-failed", message: `Unsupported public day type: ${item.type}.` });
  }

  return ok({
    date: item.date as PublicCalendarDay["date"],
    type: item.type as PublicCalendarDay["type"],
    ...(typeof item.name === "string" ? { name: item.name } : {}),
    ...(typeof item.description === "string" ? { description: item.description } : {}),
    ...(typeof item.sourceUrl === "string" ? { sourceUrl: item.sourceUrl } : {}),
    isImportant: typeof item.isImportant === "boolean" ? item.isImportant : false,
  });
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
