/**
 * Top-level popup renderer — routes to calendar or a full-screen view.
 * Exports: renderPopupApp
 * Deps: popup calendar renderer, popup screen renderer, locale
 */

import type { UserSettings } from "@daylight/domain";
import { setLanguage } from "./locale";
import type { PopupState } from "./popup-model";
import { renderPopup } from "./popup-render";
import type { CalendarHandlers } from "./popup-render";
import { renderPopupScreen, type PopupScreenContext, type PopupScreenHandlers } from "./popup-screens-render";

export function renderPopupApp(
  root: HTMLElement,
  state: PopupState,
  context: PopupScreenContext,
  calendarHandlers: CalendarHandlers,
  screenHandlers: PopupScreenHandlers,
): void {
  setLanguage(state.settings.language);
  applyColorScheme(state.settings.colorScheme);

  if (state.navigation.screen.kind === "calendar") {
    renderPopup(root, state, calendarHandlers);
    return;
  }

  const screen = renderPopupScreen(state.navigation, context, screenHandlers);
  root.replaceChildren(screen ?? document.createElement("div"));
}

function applyColorScheme(colorScheme: UserSettings["colorScheme"]): void {
  document.documentElement.classList.toggle("light", colorScheme === "light");
  document.documentElement.classList.toggle("dark", colorScheme === "dark");
}
