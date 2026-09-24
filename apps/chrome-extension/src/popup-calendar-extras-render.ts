/**
 * Moon summary row and quick diary for the calendar popup.
 * Exports: renderCalendarExtras
 * Deps: popup moon summary, locale
 */

import { makeLocalDateKey } from "@daylight/core-calendar";
import type { LocalDateKey } from "@daylight/domain";
import type { PopupState } from "./popup-model";
import { getMoonSummaryData } from "./popup-moon-summary";
import { canSaveQuickDiary } from "./quick-diary";
import { quickDiaryPlaceholder } from "./quick-diary-placeholder";
import { renderDiaryTimeline } from "./diary-timeline";
import { t } from "./locale";
import type { CalendarHandlers } from "./popup-render";

export function renderCalendarExtras(state: PopupState, handlers: CalendarHandlers): HTMLElement {
  const extras = el("div", "calendar-extras", "");
  extras.replaceChildren(
    el("div", "hairline", ""),
    renderMoonRow(state, handlers),
    el("div", "hairline", ""),
    renderQuickDiary(state, handlers),
  );
  return extras;
}

function renderMoonRow(state: PopupState, handlers: CalendarHandlers): HTMLButtonElement {
  const summary = getMoonSummaryData(state.selectedDate, state.settings.showLunarDate, 44);
  const row = button("", handlers.onOpenDetail, "moon-row");
  row.title = t("打开日期详情");
  row.setAttribute("aria-label", t("打开日期详情"));

  const disc = el("div", "moon-row-disc", "");
  disc.innerHTML = summary.discSvg;

  const title = el("div", "moon-row-title", summary.title);
  const detail = el("div", "moon-row-detail", summary.detail);
  const text = el("div", "moon-row-text", "");
  text.replaceChildren(title, detail);

  const chevron = el("span", "moon-row-chevron", "›");
  row.replaceChildren(disc, text, chevron);
  return row;
}

function renderQuickDiary(state: PopupState, handlers: CalendarHandlers): HTMLElement {
  const stack = el("div", "quick-diary-stack", "");
  const timeline = renderDiaryTimeline(state.diaryThoughts, {
    onDeleteThought: handlers.onDeleteDiaryThought,
    onToggleThought: handlers.onToggleDiaryThought,
  });
  if (timeline) stack.append(timeline);

  const row = el("div", "quick-diary", "");
  const field = document.createElement("input");
  field.type = "text";
  field.className = "quick-diary-field";
  field.placeholder = quickDiaryPlaceholder(state.selectedDate, makeTodayKey());
  field.value = "";
  field.setAttribute("aria-label", t("日记"));

  const save = document.createElement("button");
  save.type = "button";
  save.className = "quick-diary-save primary";
  save.textContent = t("保存");
  save.disabled = true;

  field.addEventListener("input", () => {
    save.disabled = !canSaveQuickDiary(field.value);
  });
  field.addEventListener("keydown", (event) => {
    if (event.key === "Enter" && canSaveQuickDiary(field.value)) handlers.onSaveQuickDiary(field.value);
  });
  save.addEventListener("click", () => handlers.onSaveQuickDiary(field.value));

  row.replaceChildren(field, save);
  stack.append(row);
  return stack;
}

function makeTodayKey(): LocalDateKey {
  const now = new Date();
  return makeLocalDateKey(now.getFullYear(), now.getMonth() + 1, now.getDate());
}

function button(label: string, onClick: () => void, className = ""): HTMLButtonElement {
  const item = document.createElement("button");
  item.className = className;
  item.textContent = label;
  item.addEventListener("click", onClick);
  return item;
}

function el<K extends keyof HTMLElementTagNameMap>(tag: K, className: string, text: string): HTMLElementTagNameMap[K] {
  const item = document.createElement(tag);
  item.className = className;
  item.textContent = text;
  return item;
}
