/**
 * Year, decade, and century period grid rendering for the popup.
 * Exports: renderPeriodGrid
 * Deps: calendar period helpers, popup model, popup render handlers
 */

import { parseLocalDateKey } from "@daylight/core-calendar";
import { buildPeriodGridItems } from "./calendar-period";
import type { PopupState } from "./popup-model";
import type { CalendarHandlers } from "./popup-render";

export function renderPeriodGrid(state: PopupState, handlers: CalendarHandlers): HTMLElement {
  const selected = parseLocalDateKey(state.selectedDate);
  const items = buildPeriodGridItems(
    state.visibleYear,
    state.visibleMonth,
    selected.year,
    selected.month,
    state.viewMode,
    state.settings.showLunarDate,
  );
  const wrap = el("div", "period-grid-wrap", "");
  const grid = el("div", "period-grid", "");
  grid.replaceChildren(...items.map((item) => renderPeriodTile(item, handlers)));
  wrap.append(grid);
  return wrap;
}

function renderPeriodTile(
  item: ReturnType<typeof buildPeriodGridItems>[number],
  handlers: CalendarHandlers,
): HTMLButtonElement {
  const classes = [
    "period-tile",
    item.isSelected ? "selected" : "",
    item.isOutsidePeriod ? "outside" : "",
    item.nextMode === "month" ? "month-tile" : "",
  ].filter(Boolean).join(" ");
  const tile = button("", () => handlers.onSelectPeriod(item.year, item.month, item.nextMode), classes);
  const title = el("span", "period-tile-title", item.title);
  tile.append(title);
  if (item.subtitle) tile.append(el("span", "period-tile-subtitle", item.subtitle));
  return tile;
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
