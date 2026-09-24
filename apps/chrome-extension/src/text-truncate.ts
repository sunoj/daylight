/**
 * Subtitle truncation for narrow calendar day cells.
 * Exports: truncateCellSubtitle
 * Deps: none
 */

export function truncateCellSubtitle(text: string, maxLength = 9): string {
  if (text.length <= maxLength) return text;
  const head = text.slice(0, maxLength);
  const lastSpace = head.lastIndexOf(" ");
  if (lastSpace >= Math.floor(maxLength * 0.45)) return `${head.slice(0, lastSpace)}…`;
  return `${head.trimEnd()}…`;
}
