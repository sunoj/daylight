import { getLunarDate, makeLocalDateKey } from "@daylight/core-calendar";
import type { CalendarViewMode, LocalDateKey, UserSettings } from "@daylight/domain";
import { calendarPeriod, lunarYearName } from "./calendar-period";
import { monthTitle, setLanguage, t } from "./locale";
import { renderCalendarExtras } from "./popup-calendar-extras-render";
import { renderMonthStack } from "./popup-calendar-grid-render";
import { renderPeriodGrid } from "./popup-period-grid-render";
import type { PopupState } from "./popup-model";

export interface CalendarHandlers {
  readonly onMoveMonth: (delta: number) => void;
  readonly onSelectDate: (date: LocalDateKey) => void;
  readonly onToday: () => void;
  readonly onZoomOut: () => void;
  readonly onSelectPeriod: (year: number, month: number | undefined, nextMode: CalendarViewMode) => void;
  readonly onOpenSettings: () => void;
  readonly onShowShortcuts: () => void;
  readonly onOpenDetail: () => void;
  readonly onSaveQuickDiary: (content: string) => void;
  readonly onDeleteDiaryThought: (id: string) => void;
  readonly onToggleDiaryThought: (id: string) => void;
}

export function renderPopup(root: HTMLElement, state: PopupState, handlers: CalendarHandlers): void {
  setLanguage(state.settings.language);
  applyColorScheme(state.settings.colorScheme);
  root.replaceChildren(
    renderToolbar(state, handlers),
    renderWorkspace(state, handlers),
    renderFooter(state, handlers),
  );
}

function renderToolbar(state: PopupState, handlers: CalendarHandlers): HTMLElement {
  const titleText = getToolbarTitle(state);
  const title = state.viewMode === "century"
    ? el("div", "title", titleText)
    : titleButton(titleText, handlers.onZoomOut, getToolbarTitleLabel(state));
  const subtitleText = getToolbarSubtitle(state);
  const subtitle = el("div", "subtle", subtitleText);
  const titleBlock = el("div", "title-block", "");
  titleBlock.replaceChildren(title, subtitle);
  const left = el("div", "", "");
  left.className = "header-side";
  left.replaceChildren(iconButton(t("上一月"), () => handlers.onMoveMonth(-1), "chevron-left"), iconButton(t("今天"), handlers.onToday, "calendar"));
  const right = el("div", "", "");
  right.className = "header-side end";
  right.replaceChildren(iconButton(t("下一月"), () => handlers.onMoveMonth(1), "chevron-right"));
  const toolbar = el("header", "month-header", "");
  toolbar.replaceChildren(left, titleBlock, right);
  return toolbar;
}

function renderWorkspace(state: PopupState, handlers: CalendarHandlers): HTMLElement {
  const workspace = el("section", "workspace", "");
  if (state.viewMode === "month") {
    workspace.append(renderMonthStack(state, handlers), renderCalendarExtras(state, handlers));
  } else {
    workspace.append(renderPeriodGrid(state, handlers));
  }
  return workspace;
}

function renderFooter(state: PopupState, handlers: CalendarHandlers): HTMLElement {
  const footer = el("footer", "footer", "");
  const today = button(t("今天"), handlers.onToday, "today-link");
  footer.replaceChildren(
    iconButton(t("设置"), handlers.onOpenSettings, "settings", "footer-button"),
    today,
    iconButton(t("显示快捷键提示"), handlers.onShowShortcuts, "info", "footer-button"),
  );
  return footer;
}

function button(label: string, onClick: () => void, className = ""): HTMLButtonElement {
  const item = document.createElement("button");
  item.className = className;
  item.textContent = label;
  item.addEventListener("click", onClick);
  return item;
}

function iconButton(label: string, onClick: () => void, iconName: string, className = "tile"): HTMLButtonElement {
  const item = button("", onClick, className);
  item.title = label;
  item.setAttribute("aria-label", label);
  item.textContent = getIconGlyph(iconName);
  return item;
}

function el<K extends keyof HTMLElementTagNameMap>(tag: K, className: string, text: string): HTMLElementTagNameMap[K] {
  const item = document.createElement(tag);
  item.className = className;
  item.textContent = text;
  return item;
}

function applyColorScheme(colorScheme: UserSettings["colorScheme"]): void {
  document.documentElement.classList.toggle("light", colorScheme === "light");
  document.documentElement.classList.toggle("dark", colorScheme === "dark");
}

function getIconGlyph(name: string): string {
  if (name === "chevron-left") return "‹";
  if (name === "chevron-right") return "›";
  if (name === "calendar") return "□";
  if (name === "settings") return "⚙";
  return "i";
}


function titleButton(label: string, onClick: () => void, ariaLabel: string): HTMLButtonElement {
  const item = document.createElement("button");
  item.className = "title period-title";
  item.textContent = label;
  item.title = ariaLabel;
  item.setAttribute("aria-label", ariaLabel);
  item.addEventListener("click", onClick);
  return item;
}

function getToolbarTitle(state: PopupState): string {
  if (state.viewMode === "month") return monthTitle(state.visibleYear, state.visibleMonth);
  return calendarPeriod(state.visibleYear, state.visibleMonth, state.viewMode).title;
}

function getToolbarTitleLabel(state: PopupState): string {
  return getToolbarTitle(state);
}

function getToolbarSubtitle(state: PopupState): string {
  if (!state.settings.showLunarDate) return "";
  if (state.viewMode === "month") return getLunarMonthLabel(state.visibleYear, state.visibleMonth);
  if (state.viewMode === "year") return t(lunarYearName(state.visibleYear) ?? "");
  return "";
}

function getLunarMonthLabel(year: number, month: number): string {
  const lunar = getLunarDate(makeLocalDateKey(year, month, 1));
  return lunar.ok ? t(`${lunar.value.yearName}年 · ${lunar.value.monthName}月`) : "";
}
