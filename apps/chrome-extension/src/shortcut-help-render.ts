/**
 * Keyboard shortcut reference screen content.
 * Exports: renderShortcutHelpList
 * Deps: popup shortcuts table, locale
 */

import { SHORTCUT_BINDINGS } from "./popup-shortcuts";
import { t } from "./locale";

export function renderShortcutHelpList(): HTMLElement {
  const list = el("div", "shortcut-list", "");
  list.replaceChildren(...SHORTCUT_BINDINGS.map(renderRow));
  return list;
}

function renderRow(binding: typeof SHORTCUT_BINDINGS[number]): HTMLElement {
  const label = el("span", "shortcut-label", t(binding.labelKey));
  const keys = el("span", "shortcut-keys", "");
  keys.replaceChildren(...binding.displays.map((display) => el("span", "shortcut-key", display)));
  const row = el("div", "shortcut-row", "");
  row.replaceChildren(label, keys);
  return row;
}

function el<K extends keyof HTMLElementTagNameMap>(tag: K, className: string, text: string): HTMLElementTagNameMap[K] {
  const item = document.createElement(tag);
  item.className = className;
  item.textContent = text;
  return item;
}
