/**
 * Settings navigation rows for holidays and about screens.
 * Exports: renderSettingsNav
 * Deps: locale
 */

import { t } from "./locale";

export interface SettingsNavHandlers {
  readonly onOpenHolidays: () => void;
  readonly onOpenInfo: () => void;
}

export function renderSettingsNav(handlers: SettingsNavHandlers): HTMLElement {
  const wrap = el("div", "settings-nav", "");
  wrap.replaceChildren(
    sectionLabel(t("数据与同步")),
    navCard(navRow("☷", t("订阅法定节假日"), t("选择多个来源，自动标注放假与调休"), handlers.onOpenHolidays)),
    sectionLabel(t("关于昼间")),
    navCard(navRow("i", t("关于昼间"), t("版本、常见问题与更新日志"), handlers.onOpenInfo)),
  );
  return wrap;
}

function navCard(row: HTMLElement): HTMLElement {
  const card = el("div", "settings-card", "");
  card.append(row);
  return card;
}

function navRow(icon: string, title: string, subtitle: string, onClick: () => void): HTMLElement {
  const row = el("div", "settings-row settings-row-nav", "");
  const text = el("div", "settings-row-text", "");
  text.replaceChildren(el("div", "settings-row-title", title), el("div", "settings-row-sub", subtitle));
  row.replaceChildren(el("div", "settings-icon-tile", icon), text, el("span", "settings-chevron", "›"));
  row.addEventListener("click", onClick);
  row.tabIndex = 0;
  row.addEventListener("keydown", (event) => {
    if (event.key !== "Enter" && event.key !== " ") return;
    event.preventDefault();
    onClick();
  });
  return row;
}

function sectionLabel(label: string): HTMLElement {
  return el("div", "settings-section-label", label);
}

function el<K extends keyof HTMLElementTagNameMap>(tag: K, className: string, text: string): HTMLElementTagNameMap[K] {
  const item = document.createElement(tag);
  item.className = className;
  item.textContent = text;
  return item;
}
