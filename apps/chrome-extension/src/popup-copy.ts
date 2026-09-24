import type { DateMark } from "@daylight/domain";
import { t } from "./locale";

export const detailCopy = {
  get today() { return t("今天"); },
  get marks() { return t("标记"); },
  get diary() { return t("日记"); },
  get add() { return t("添加"); },
  get noMarks() { return t("无标记"); },
  get saveMark() { return t("保存标记"); },
  get saveDiary() { return t("保存日记"); },
  get saved() { return t("已保存"); },
  get justNow() { return t("刚刚"); },
  diaryLimit: 500,
  weekLabel(week: number) { return t("第 {week} 周").replace("{week}", String(week)); },
  // Just the number, matching design section 04 (the left label already says 标记).
  // Avoids the redundant "1 个标记" and the ungrammatical English "1 marks".
  marksCount(count: number) { return String(count); },
  markTypes: {
    get oneTime() { return t("单次"); },
    get yearly() { return t("每年"); },
    get monthly() { return t("每月"); },
  } satisfies Readonly<Record<DateMark["type"], string>>,
} as const;
