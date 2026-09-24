/**
 * Full-screen popup views for detail, settings, holidays, info, and shortcuts.
 * Exports: renderPopupScreen, PopupScreenContext
 * Deps: detail, settings, holiday, info, shortcut renderers, screen shell
 */

import type { DetailState } from "./detail-model";
import { renderDetail } from "./detail-render";
import { renderHolidaySettings } from "./holiday-render";
import { renderAboutPanel } from "./info-render";
import { t } from "./locale";
import type { OptionsState } from "./options-model";
import type { DetailHandlers, OptionsHandlers } from "./page-handlers";
import { renderScreenShell } from "./popup-shell-render";
import { screenTitleKey, type PopupNavigation } from "./popup-router";
import { renderSettings } from "./settings-render";
import { renderSettingsNav } from "./settings-nav-render";
import { renderShortcutHelpList } from "./shortcut-help-render";

export interface PopupScreenContext {
  readonly detail?: DetailState | undefined;
  readonly options?: OptionsState | undefined;
}

export interface PopupScreenHandlers extends DetailHandlers, OptionsHandlers {
  readonly onBack: () => void;
  readonly onOpenHolidays: () => void;
  readonly onOpenInfo: () => void;
}

export function renderPopupScreen(
  navigation: PopupNavigation,
  context: PopupScreenContext,
  handlers: PopupScreenHandlers,
): HTMLElement | null {
  const { screen } = navigation;
  if (screen.kind === "calendar") return null;

  const title = t(screenTitleKey(screen));
  switch (screen.kind) {
    case "detail":
      return renderDetailScreen(title, context.detail, handlers);
    case "settings":
      return renderSettingsScreen(title, context.options, handlers);
    case "holidays":
      return renderHolidaysScreen(title, context.options, handlers);
    case "info": {
      const body = el("div", "screen-content", "");
      body.append(renderAboutPanel());
      return renderScreenShell(title, handlers.onBack, body);
    }
    case "shortcuts": {
      const body = el("div", "screen-content", "");
      body.append(renderShortcutHelpList());
      return renderScreenShell(title, handlers.onBack, body);
    }
    default:
      return null;
  }
}

function renderDetailScreen(title: string, state: DetailState | undefined, handlers: DetailHandlers & BackHandler): HTMLElement {
  const body = el("div", "screen-content", "");
  if (state) body.append(renderDetail(state, handlers));
  return renderScreenShell(title, handlers.onBack, body);
}

function renderSettingsScreen(title: string, state: OptionsState | undefined, handlers: PopupScreenHandlers): HTMLElement {
  const body = el("div", "screen-content", "");
  if (state) {
    body.append(renderSettings(state, handlers), renderSettingsNav(handlers));
  }
  return renderScreenShell(title, handlers.onBack, body);
}

function renderHolidaysScreen(title: string, state: OptionsState | undefined, handlers: OptionsHandlers & BackHandler): HTMLElement {
  const body = el("div", "screen-content", "");
  if (state) body.append(renderHolidaySettings(state, handlers, { showHead: false }));
  return renderScreenShell(title, handlers.onBack, body);
}

interface BackHandler {
  readonly onBack: () => void;
}

function el<K extends keyof HTMLElementTagNameMap>(tag: K, className: string, text: string): HTMLElementTagNameMap[K] {
  const item = document.createElement(tag);
  item.className = className;
  item.textContent = text;
  return item;
}
