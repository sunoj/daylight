/**
 * Minimal HTTP client port for sync modules.
 * Exports: HttpClient, JsonResponse
 * Deps: shared Result type
 */

import type { Result } from "@daylight/domain";

export interface JsonResponse {
  readonly status: number;
  readonly body: unknown;
}

export interface HttpClient {
  getJson(url: string): Promise<Result<JsonResponse>>;
}
