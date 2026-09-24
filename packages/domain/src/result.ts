/**
 * Shared Result contract for expected domain and adapter failures.
 * Exports: Result, DomainError, ok, err
 * Deps: none
 */

export type DomainErrorCode =
  | "invalid-date"
  | "not-found"
  | "storage-failed"
  | "sync-failed"
  | "validation-failed";

export interface DomainError {
  readonly code: DomainErrorCode;
  readonly message: string;
  readonly cause?: unknown;
}

export type Result<T, E = DomainError> =
  | { readonly ok: true; readonly value: T }
  | { readonly ok: false; readonly error: E };

export function ok<T>(value: T): Result<T> {
  return { ok: true, value };
}

export function err<E extends DomainError>(error: E): Result<never, E> {
  return { ok: false, error };
}
