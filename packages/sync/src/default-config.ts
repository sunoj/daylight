/**
 * Default config parsing for remote source discovery.
 * Exports: DefaultConfig, parseDefaultConfigPayload
 * Deps: domain remote source types
 */

import { err, ok } from "@daylight/domain";
import type { RemoteDataSource, Result } from "@daylight/domain";

export interface DefaultConfig {
  readonly sources: readonly RemoteDataSource[];
  readonly uninstallUrl?: string;
}

export function parseDefaultConfigPayload(payload: unknown): Result<DefaultConfig> {
  if (!isRecord(payload)) {
    return err({ code: "validation-failed", message: "Default config payload must be an object." });
  }

  const sources = Array.isArray(payload.sources) ? parseSources(payload.sources) : ok([]);
  if (!sources.ok) return sources;

  return ok({
    sources: sources.value,
    ...(typeof payload.uninstallUrl === "string" ? { uninstallUrl: payload.uninstallUrl } : {}),
  });
}

function parseSources(sources: readonly unknown[]): Result<readonly RemoteDataSource[]> {
  const parsedSources: RemoteDataSource[] = [];
  for (const source of sources) {
    const parsed = parseSource(source);
    if (!parsed.ok) return parsed;
    parsedSources.push(parsed.value);
  }
  return ok(parsedSources);
}

function parseSource(source: unknown): Result<RemoteDataSource> {
  if (!isRecord(source)) {
    return err({ code: "validation-failed", message: "Remote source must be an object." });
  }
  if (source.kind !== "public-calendar") {
    return err({ code: "validation-failed", message: "Remote source has an unsupported kind." });
  }
  if (typeof source.url !== "string" || typeof source.version !== "string") {
    return err({ code: "validation-failed", message: "Remote source requires url and version." });
  }
  return ok({ kind: source.kind, url: source.url, version: source.version });
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
