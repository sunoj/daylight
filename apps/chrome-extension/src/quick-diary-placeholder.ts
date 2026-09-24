/**
 * Date-aware quick diary input placeholder text.
 * Exports: quickDiaryPlaceholder
 * Deps: core-calendar date parsing, locale helpers
 */

import { parseLocalDateKey } from "@daylight/core-calendar";
import type { LocalDateKey } from "@daylight/domain";
import { getLanguage, monthShort, t } from "./locale";

export function quickDiaryPlaceholder(selectedDate: LocalDateKey, today: LocalDateKey): string {
  if (selectedDate === today) return t("记一笔今天…");
  const parts = parseLocalDateKey(selectedDate);
  switch (getLanguage()) {
    case "zh":
    case "zh-Hant":
      return t(`记一笔 ${monthShort(parts.month)}${parts.day}日…`);
    case "th":
      return `บันทึก ${parts.day} ${monthShort(parts.month)}…`;
    default:
      return `Note ${monthShort(parts.month)} ${parts.day}…`;
  }
}
