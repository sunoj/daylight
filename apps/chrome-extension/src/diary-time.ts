/**
 * Diary thought time labels shared by popup and detail screens.
 * Exports: formatDiaryThoughtTime
 * Deps: none
 */

export function formatDiaryThoughtTime(iso: string, now: Date = new Date()): string {
  const saved = new Date(iso);
  if (Number.isNaN(saved.getTime())) return "";
  const elapsed = now.getTime() - saved.getTime();
  if (elapsed >= 0 && elapsed < 60_000) return "just-now";
  const sameDay = saved.getFullYear() === now.getFullYear()
    && saved.getMonth() === now.getMonth()
    && saved.getDate() === now.getDate();
  if (sameDay) {
    return saved.toLocaleTimeString(undefined, { hour: "2-digit", minute: "2-digit", hour12: false });
  }
  return saved.toISOString().slice(0, 10);
}
