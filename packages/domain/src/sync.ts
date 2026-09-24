/**
 * Shared sync status and remote data metadata models.
 * Exports: SyncStatus, SyncState, RemoteDataSource
 * Deps: date primitives
 */

import type { DateRange } from "./date";

export type SyncStatus = "idle" | "running" | "succeeded" | "failed";

export interface SyncState {
  readonly status: SyncStatus;
  readonly lastStartedAt?: string;
  readonly lastSucceededAt?: string;
  readonly errorMessage?: string;
}

export type RemoteDataSourceKind = "public-calendar";

export interface RemoteDataSource {
  readonly kind: RemoteDataSourceKind;
  readonly url: string;
  readonly version: string;
  readonly coveredRange?: DateRange;
}
