/**
 * Popup screen routing — one visible screen at a time with a back stack.
 * Exports: PopupScreen, PopupNavigation, pushScreen, popScreen, navigateTo
 * Deps: none
 */

export type PopupScreen =
  | { readonly kind: "calendar" }
  | { readonly kind: "detail" }
  | { readonly kind: "settings" }
  | { readonly kind: "holidays" }
  | { readonly kind: "info" }
  | { readonly kind: "shortcuts" };

export interface PopupNavigation {
  readonly screen: PopupScreen;
  readonly stack: readonly PopupScreen[];
}

export const CALENDAR_NAVIGATION: PopupNavigation = {
  screen: { kind: "calendar" },
  stack: [],
};

export function pushScreen(nav: PopupNavigation, screen: PopupScreen): PopupNavigation {
  if (screen.kind === "calendar") return CALENDAR_NAVIGATION;
  return { screen, stack: [...nav.stack, nav.screen] };
}

export function popScreen(nav: PopupNavigation): PopupNavigation {
  if (nav.stack.length === 0) return nav;
  const screen = nav.stack[nav.stack.length - 1];
  if (!screen) return nav;
  return { screen, stack: nav.stack.slice(0, -1) };
}

export function canGoBack(nav: PopupNavigation): boolean {
  return nav.stack.length > 0;
}

export function navigateTo(nav: PopupNavigation, kind: PopupScreen["kind"]): PopupNavigation {
  return pushScreen(nav, { kind });
}

export function screenTitleKey(screen: PopupScreen): string {
  switch (screen.kind) {
    case "calendar":
      return "";
    case "detail":
      return "日期详情";
    case "settings":
      return "设置";
    case "holidays":
      return "订阅法定节假日";
    case "info":
      return "关于昼间";
    case "shortcuts":
      return "显示快捷键提示";
  }
}
