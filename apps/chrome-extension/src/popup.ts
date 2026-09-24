/**
 * Chrome popup bootstrap for the Daylight rewrite.
 * Exports: none, starts the popup controller
 * Deps: Chrome repositories, popup model, popup app renderer, shortcut table
 */

import {
  appendDiaryThought,
  cycleHolidayColor,
  deleteDiaryThought,
  deleteMark,
  saveHolidayUpdateWeekly,
  saveSelectedMark,
  saveSettings,
  toggleDiaryThought,
  toggleHolidaySource,
  updateCustomHoliday,
} from "./calendar-data";
import { createChromeRepositories } from "./chrome-repositories";
import { loadDetailState } from "./detail-model";
import type { DetailState } from "./detail-model";
import { refreshHolidaySubscriptions } from "./holiday-subscriptions";
import type { HolidayRefreshResult } from "./holiday-subscriptions";
import { resolveToolbarTheme } from "./icon-theme";
import { t } from "./locale";
import { loadOptionsState } from "./options-model";
import type { OptionsState } from "./options-model";
import { renderPopupApp } from "./popup-app-render";
import {
  goBack,
  jumpToCurrentMonth,
  jumpToToday,
  loadPopupState,
  moveDay,
  moveMonth,
  openScreen,
  selectDate,
  selectPeriod,
  zoomIn,
  zoomOut,
} from "./popup-model";
import type { PopupState } from "./popup-model";
import type { CalendarHandlers } from "./popup-render";
import type { PopupScreenHandlers } from "./popup-screens-render";
import { isArrowShortcut, isTypingTarget, resolveShortcutAction } from "./popup-shortcuts";
import type { ShortcutAction } from "./popup-shortcuts";

const repositories = createChromeRepositories();
const root = document.getElementById("app");
if (!root) throw new Error("Missing app root.");
const appRoot: HTMLElement = root;

let state: PopupState | undefined;
let detailState: DetailState | undefined;
let optionsState: OptionsState | undefined;
let holidayMessage = "";

async function refresh(nextState?: Parameters<typeof loadPopupState>[1]): Promise<void> {
  state = await loadPopupState(repositories, nextState ?? state);
  detailState = state.navigation.screen.kind === "detail"
    ? await loadDetailState(repositories, state.selectedDate)
    : undefined;
  if (state.navigation.screen.kind === "settings" || state.navigation.screen.kind === "holidays") {
    optionsState = await loadOptionsState(repositories, { holidayMessage });
    holidayMessage = optionsState.holidayMessage;
  }
  renderPopupApp(appRoot, state, { detail: detailState, options: optionsState }, createCalendarHandlers(), createScreenHandlers());
}

function requireState(): PopupState {
  if (!state) throw new Error("Popup state is not loaded.");
  return state;
}

function createCalendarHandlers(): CalendarHandlers {
  return {
    onMoveMonth: (delta) => void refresh(moveMonth(requireState(), delta)),
    onSelectDate: (date) => void refresh(selectDate(requireState(), date)),
    onToday: () => void refresh(jumpToToday()),
    onZoomOut: () => void refresh(zoomOut(requireState())),
    onSelectPeriod: (year, month, nextMode) => void refresh(selectPeriod(requireState(), year, month ?? 1, nextMode)),
    onOpenSettings: () => void refresh(openScreen(requireState(), "settings")),
    onShowShortcuts: () => void refresh(openScreen(requireState(), "shortcuts")),
    onOpenDetail: () => void refresh(openScreen(requireState(), "detail")),
    onSaveQuickDiary: (content) => void saveQuickDiary(content),
    onDeleteDiaryThought: (id) => void deleteDiaryThoughtAndRefresh(id),
    onToggleDiaryThought: (id) => void toggleDiaryThoughtAndRefresh(id),
  };
}

async function saveQuickDiary(content: string): Promise<void> {
  const trimmed = content.trim();
  if (!trimmed) return;
  await appendDiaryThought(repositories, requireState().selectedDate, trimmed);
  await refresh(requireState());
}

async function deleteDiaryThoughtAndRefresh(id: string): Promise<void> {
  await deleteDiaryThought(repositories, id);
  await refresh(requireState());
}

async function toggleDiaryThoughtAndRefresh(id: string): Promise<void> {
  await toggleDiaryThought(repositories, id);
  await refresh(requireState());
}

function createScreenHandlers(): PopupScreenHandlers {
  return {
    onBack: () => void refresh(goBack(requireState())),
    onOpenHolidays: () => void refresh(openScreen(requireState(), "holidays")),
    onOpenInfo: () => void refresh(openScreen(requireState(), "info")),
    onSaveMark: (type, content) => void saveAndRefreshDetail(() => saveSelectedMark(repositories, requireDetailDate(), type, content)),
    onDeleteMark: (mark) => void saveAndRefreshDetail(() => deleteMark(repositories, mark)),
    onSaveDiary: (content) => void saveAndRefreshDetail(() => appendDiaryThought(repositories, requireDetailDate(), content)),
    onDeleteDiaryThought: (id) => void saveAndRefreshDetail(() => deleteDiaryThought(repositories, id)),
    onToggleDiaryThought: (id) => void saveAndRefreshDetail(() => toggleDiaryThought(repositories, id)),
    onSaveSettings: (settings) => void saveAndRefreshOptions(async () => {
      await saveSettings(repositories, settings);
      chrome.runtime.sendMessage({ type: "settings-changed" });
    }),
    onToggleHolidaySource: (sourceId) => void saveAndRefreshOptions(() => toggleHolidaySource(repositories, requireOptionsState().settings, sourceId)),
    onCycleHolidayColor: (subscriptionId) => void saveAndRefreshOptions(() => cycleHolidayColor(repositories, requireOptionsState().settings, subscriptionId)),
    onUpdateCustomHoliday: (patch) => void saveAndRefreshOptions(() => updateCustomHoliday(repositories, requireOptionsState().settings, patch)),
    onSaveHolidayUpdateWeekly: (weekly) => void saveAndRefreshOptions(() => saveHolidayUpdateWeekly(repositories, requireOptionsState().settings, weekly)),
    onRefreshHolidays: () => void refreshHolidays(),
  };
}

function requireDetailDate(): DetailState["selectedDate"] {
  return requireState().selectedDate;
}

function requireOptionsState(): OptionsState {
  if (!optionsState) throw new Error("Options state is not loaded.");
  return optionsState;
}

async function saveAndRefreshDetail(action: () => Promise<void>): Promise<void> {
  await action();
  await refresh(requireState());
}

async function saveAndRefreshOptions(action: () => Promise<void>): Promise<void> {
  await action();
  await refresh(requireState());
}

async function refreshHolidays(): Promise<void> {
  holidayMessage = t("正在同步…");
  await refresh(requireState());
  const results = await refreshHolidaySubscriptions(repositories, { requestCustomPermissions: true });
  const imported = results.reduce((sum, result) => sum + result.count, 0);
  holidayMessage = getHolidayMessage(results, imported);
  await refresh(requireState());
}

function getHolidayMessage(results: readonly HolidayRefreshResult[], imported: number): string {
  const failures = results.filter((result) => result.status !== "success");
  if (results.length === 0) return t("未订阅");
  if (failures.length === 0) return `${t("已订阅")} · ${imported}`;
  if (failures.some((result) => result.status === "permission-denied")) return t("未授予订阅权限");
  if (imported > 0) return `${t("同步失败")} · ${failures.length}`;
  return failures.length === 1 ? t("同步失败") : `${t("同步失败")} · ${failures.length}`;
}

function handleShortcutAction(action: ShortcutAction): void {
  const current = requireState();
  if (action === "prevDay" || action === "nextDay") {
    if (current.navigation.screen.kind !== "calendar" || current.viewMode !== "month") return;
  }
  if ((action === "prevMonth" || action === "nextMonth") && current.navigation.screen.kind !== "calendar") return;

  switch (action) {
    case "prevDay":
      void refresh(moveDay(current, -1));
      break;
    case "nextDay":
      void refresh(moveDay(current, 1));
      break;
    case "prevMonth":
      void refresh(moveMonth(current, -1));
      break;
    case "nextMonth":
      void refresh(moveMonth(current, 1));
      break;
    case "openDetail":
      void refresh(openScreen(current, "detail"));
      break;
    case "backToCurrentMonth":
      void refresh(jumpToCurrentMonth(current));
      break;
    case "openSettings":
      void refresh(openScreen(current, "settings"));
      break;
    case "showShortcutHelp":
      void refresh(openScreen(current, "shortcuts"));
      break;
    case "goBack":
      if (current.navigation.stack.length > 0) void refresh(goBack(current));
      break;
  }
}

function installShortcutListeners(): void {
  document.addEventListener("keydown", (event) => {
    if (isTypingTarget(event.target)) return;
    if (event.key === "Escape") {
      const current = state;
      if (current?.navigation.screen.kind === "calendar" && current.viewMode !== "month") {
        event.preventDefault();
        void refresh(zoomIn(current));
        return;
      }
    }
    if (isArrowShortcut(event)) event.preventDefault();
  });
  document.addEventListener("keyup", (event) => {
    const action = resolveShortcutAction(event);
    if (!action) return;
    event.preventDefault();
    handleShortcutAction(action);
  });
}

function installToolbarThemeReporter(): void {
  const media = window.matchMedia("(prefers-color-scheme: dark)");
  const report = (): void => {
    chrome.runtime.sendMessage({ type: "toolbar-theme-changed", theme: resolveToolbarTheme(media.matches) });
  };
  report();
  media.addEventListener("change", report);
}

installShortcutListeners();
installToolbarThemeReporter();
void refresh();
