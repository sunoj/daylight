/**
 * Holiday subscription settings screen renderer.
 * Exports: renderHolidaySettings
 * Deps: sync holiday presets, popup state and handlers, locale
 */

import { HOLIDAY_SOURCES } from "@daylight/sync";
import type { HolidaySource, HolidaySourceCount } from "@daylight/sync";
import type { HolidaySubscription } from "@daylight/domain";
import { t } from "./locale";
import type { OptionsState } from "./options-model";
import type { OptionsHandlers } from "./page-handlers";

export function renderHolidaySettings(state: OptionsState, handlers: OptionsHandlers, options?: { readonly showHead?: boolean }): HTMLElement {
  const panel = el("section", "holidays-panel", "");
  const custom = findSubscription(state.settings.holidaySubscriptions, "custom");
  const children: HTMLElement[] = [];
  if (options?.showHead !== false) children.push(renderHeader());
  children.push(
    sectionLabel(t("来源")),
    renderSourceGroup(state, handlers),
    ...renderCustomRows(custom, handlers),
    sectionLabel(t("自动更新")),
    renderUpdateRow(state, handlers),
    renderRefreshButton(handlers),
    renderNote(state),
  );
  panel.replaceChildren(...children);
  return panel;
}

function renderHeader(): HTMLElement {
  const title = el("div", "holiday-title", t("订阅法定节假日"));
  const sub = el("div", "subtle", t("选择多个来源，自动标注放假与调休"));
  const text = el("div", "", "");
  text.replaceChildren(title, sub);
  const row = el("div", "holiday-head", "");
  row.replaceChildren(text);
  return row;
}

function renderSourceGroup(state: OptionsState, handlers: OptionsHandlers): HTMLElement {
  const group = el("div", "holiday-group", "");
  group.replaceChildren(...HOLIDAY_SOURCES.map((source) => renderSourceRow(source, state, handlers)));
  return group;
}

function renderSourceRow(source: HolidaySource, state: OptionsState, handlers: OptionsHandlers): HTMLElement {
  const subscription = findSubscription(state.settings.holidaySubscriptions, source.id);
  const checkbox = input("checkbox", "");
  checkbox.checked = !!subscription;
  checkbox.addEventListener("change", () => handlers.onToggleHolidaySource(source.id));
  const labels = el("div", "holiday-source-text", "");
  labels.replaceChildren(el("span", "holiday-source-name", t(source.name)), detailLine(source, !!subscription));
  const row = el("label", subscription ? "holiday-source selected" : "holiday-source", "");
  row.replaceChildren(checkbox, labels, spacer(), ...swatch(subscription, handlers), el("span", "holiday-count", countLabel(source.count)));
  return row;
}

function detailLine(source: HolidaySource, selected: boolean): HTMLElement {
  return selected || source.id === "custom"
    ? el("span", "holiday-source-detail", t(source.detail))
    : el("span", "holiday-source-detail empty", "");
}

function swatch(subscription: HolidaySubscription | undefined, handlers: OptionsHandlers): readonly HTMLElement[] {
  if (!subscription) return [];
  const button = el("button", `holiday-swatch holiday-${subscription.colorId}`, "");
  button.title = colorName(subscription.colorId);
  button.addEventListener("click", (event) => {
    event.preventDefault();
    handlers.onCycleHolidayColor(subscription.id);
  });
  return [button];
}

function renderCustomRows(subscription: HolidaySubscription | undefined, handlers: OptionsHandlers): readonly HTMLElement[] {
  if (!subscription) return [];
  return [
    sectionLabel(t("订阅链接")),
    fieldRow(t("名称"), t("留空则自动读取"), subscription.name, (name) => handlers.onUpdateCustomHoliday({ name })),
    fieldRow("", "https://.../holidays.ics", subscription.customURL, (customURL) => handlers.onUpdateCustomHoliday({ customURL })),
  ];
}

function fieldRow(label: string, placeholder: string, value: string, onChange: (value: string) => void): HTMLElement {
  const control = input("text", value);
  control.placeholder = placeholder;
  control.addEventListener("change", () => onChange(control.value));
  const row = el("label", "holiday-field-row", "");
  row.replaceChildren(el("span", "holiday-field-label", label), control);
  return row;
}

function renderUpdateRow(state: OptionsState, handlers: OptionsHandlers): HTMLElement {
  const row = el("label", "holiday-update-row", "");
  const checkbox = input("checkbox", "");
  checkbox.checked = state.settings.holidayUpdateWeekly;
  checkbox.addEventListener("change", () => handlers.onSaveHolidayUpdateWeekly(checkbox.checked));
  row.replaceChildren(el("span", "", t("每周")), checkbox);
  return row;
}

function renderRefreshButton(handlers: OptionsHandlers): HTMLElement {
  return button(t("订阅并标注"), handlers.onRefreshHolidays, "holiday-refresh primary");
}

function renderNote(state: OptionsState): HTMLElement {
  const count = state.holidayHits.length;
  const fallback = state.settings.holidaySubscriptions.some((item) => item.enabled) ? `${t("订阅节假日")} · ${count}` : t("未订阅");
  return el("div", "holiday-note", state.holidayMessage || fallback);
}

function countLabel(count: HolidaySourceCount): string {
  if (count.kind === "daysPerYear") return t("{count} 天 / 年").replace("{count}", String(count.value));
  if (count.kind === "days") return t("{count} 天").replace("{count}", String(count.value));
  if (count.kind === "unknown") return "—";
  return "";
}

function findSubscription(subscriptions: readonly HolidaySubscription[], sourceId: string): HolidaySubscription | undefined {
  return subscriptions.find((subscription) => subscription.sourceId === sourceId && subscription.enabled);
}

function colorName(id: string): string {
  if (id === "stone") return t("石蓝");
  if (id === "olive") return t("橄榄");
  if (id === "amber") return t("琥珀");
  if (id === "green") return t("绿");
  return t("铁锈");
}

function sectionLabel(label: string): HTMLElement {
  return el("div", "holiday-section-label", label);
}

function spacer(): HTMLElement {
  return el("span", "spacer", "");
}

function button(label: string, onClick: () => void, className = ""): HTMLButtonElement {
  const item = document.createElement("button");
  item.className = className;
  item.textContent = label;
  item.addEventListener("click", onClick);
  return item;
}

function input(type: string, value: string): HTMLInputElement {
  const item = document.createElement("input");
  item.type = type;
  item.value = value;
  return item;
}

function el<K extends keyof HTMLElementTagNameMap>(tag: K, className: string, text: string): HTMLElementTagNameMap[K] {
  const item = document.createElement(tag);
  item.className = className;
  item.textContent = text;
  return item;
}
