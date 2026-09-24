/**
 * Popup keyboard shortcut table and key resolution.
 * Exports: ShortcutAction, SHORTCUT_BINDINGS, resolveShortcutAction, isTypingTarget, shortcutHelpRows
 * Deps: none
 */

export type ShortcutAction =
  | "prevDay"
  | "nextDay"
  | "prevMonth"
  | "nextMonth"
  | "openDetail"
  | "backToCurrentMonth"
  | "openSettings"
  | "showShortcutHelp"
  | "goBack";

interface KeyMatcher {
  readonly key?: string;
  readonly code?: string;
  readonly shiftKey?: boolean;
}

export interface ShortcutBinding {
  readonly action: ShortcutAction;
  readonly labelKey: string;
  readonly displays: readonly string[];
  readonly matchers: readonly KeyMatcher[];
}

export const SHORTCUT_BINDINGS: readonly ShortcutBinding[] = [
  {
    action: "prevDay",
    labelKey: "上一天",
    displays: ["←"],
    matchers: [{ code: "ArrowLeft" }],
  },
  {
    action: "nextDay",
    labelKey: "下一天",
    displays: ["→"],
    matchers: [{ code: "ArrowRight" }],
  },
  {
    action: "prevMonth",
    labelKey: "上个月",
    displays: ["↑"],
    matchers: [{ code: "ArrowUp" }],
  },
  {
    action: "nextMonth",
    labelKey: "下个月",
    displays: ["↓"],
    matchers: [{ code: "ArrowDown" }],
  },
  {
    action: "openDetail",
    labelKey: "打开日期详情",
    displays: ["d"],
    matchers: [{ key: "d", shiftKey: false }],
  },
  {
    action: "backToCurrentMonth",
    labelKey: "回到当前月份",
    displays: ["m", "o"],
    matchers: [{ key: "m", shiftKey: false }, { key: "o", shiftKey: false }],
  },
  {
    action: "openSettings",
    labelKey: "进入设置页面",
    displays: ["s", "c"],
    matchers: [{ key: "s", shiftKey: false }, { key: "c", shiftKey: false }],
  },
  {
    action: "showShortcutHelp",
    labelKey: "显示快捷键提示",
    displays: ["h", "shift+?"],
    matchers: [{ key: "h", shiftKey: false }, { key: "?", shiftKey: true }],
  },
  {
    action: "goBack",
    labelKey: "返回上一屏",
    displays: ["w"],
    matchers: [{ key: "w", shiftKey: false }],
  },
];

export function isTypingTarget(target: EventTarget | null): boolean {
  if (!target || !(target instanceof HTMLElement)) return false;
  const tag = target.tagName;
  if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT") return true;
  return target.isContentEditable;
}

export function isArrowShortcut(event: KeyboardEvent): boolean {
  if (isTypingTarget(event.target)) return false;
  return event.code === "ArrowLeft" || event.code === "ArrowRight" || event.code === "ArrowUp" || event.code === "ArrowDown";
}

export function resolveShortcutAction(event: KeyboardEvent): ShortcutAction | null {
  if (isTypingTarget(event.target)) return null;
  for (const binding of SHORTCUT_BINDINGS) {
    if (binding.matchers.some((matcher) => matchesMatcher(event, matcher))) return binding.action;
  }
  return null;
}

export function shortcutHelpRows(): readonly { readonly labelKey: string; readonly displays: readonly string[] }[] {
  return SHORTCUT_BINDINGS.map((binding) => ({ labelKey: binding.labelKey, displays: binding.displays }));
}

function matchesMatcher(event: KeyboardEvent, matcher: KeyMatcher): boolean {
  if (matcher.code !== undefined && event.code !== matcher.code) return false;
  if (matcher.key !== undefined && event.key.toLowerCase() !== matcher.key.toLowerCase()) return false;
  if (matcher.shiftKey !== undefined && event.shiftKey !== matcher.shiftKey) return false;
  return true;
}
