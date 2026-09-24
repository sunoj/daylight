/**
 * Grouped settings panel renderer for the options page.
 * Exports: renderSettings
 * Deps: locale, options state and handlers, Chrome manifest version
 */

import type { UserSettings } from "@daylight/domain";
import { t } from "./locale";
import type { OptionsState } from "./options-model";
import type { OptionsHandlers } from "./page-handlers";

export function renderSettings(state: OptionsState, handlers: OptionsHandlers): HTMLElement {
  const panel = el("section", "settings-panel", "");
  const settings = state.settings;
  panel.replaceChildren(
    renderHeader(),
    section(t("显示"), [
      languageRow(settings, handlers),
      toggleRow("lunar", "☽", t("显示农历"), settings.showLunarDate, (value) => handlers.onSaveSettings({ ...settings, showLunarDate: value })),
      toggleRow("weeks", "#", t("显示周数"), settings.showWeekNumbers, (value) => handlers.onSaveSettings({ ...settings, showWeekNumbers: value })),
    ]),
    section(t("日历"), [
      selectRow("calendar", "◷", t("日历类型"), settings.calendarType, calendarTypeOptions(), (value) => handlers.onSaveSettings({ ...settings, calendarType: value })),
    ]),
    section(t("工具栏"), [
      selectRow("icon", "□", t("图标样式"), settings.actionIconMode, actionIconModeOptions(), (value) => handlers.onSaveSettings({ ...settings, actionIconMode: value })),
    ]),
  );
  return panel;
}

function renderHeader(): HTMLElement {
  const head = el("div", "settings-panel-head", "");
  head.replaceChildren(
    el("div", "settings-panel-title", t("设置")),
    el("span", "settings-version-pill", getExtensionVersion()),
  );
  return head;
}

function section(label: string, rows: readonly HTMLElement[]): HTMLElement {
  const wrap = el("div", "", "");
  wrap.replaceChildren(el("div", "settings-section-label", label), card(rows));
  return wrap;
}

function card(rows: readonly HTMLElement[]): HTMLElement {
  const group = el("div", "settings-card", "");
  group.replaceChildren(...rows);
  return group;
}

function languageRow(settings: UserSettings, handlers: OptionsHandlers): HTMLElement {
  const row = baseRow("文", t("语言"), { titleId: "settings-language-title" });
  const control = el("div", "settings-row-control", "");
  const segmented = segmentedControl(
    languageOptions(),
    settings.language,
    (value) => handlers.onSaveSettings({ ...settings, language: value }),
    t("语言"),
  );
  segmented.setAttribute("aria-labelledby", "settings-language-title");
  control.append(segmented);
  row.append(control);
  return row;
}

function toggleRow(id: string, icon: string, label: string, checked: boolean, onChange: (value: boolean) => void): HTMLElement {
  const input = document.createElement("input");
  input.type = "checkbox";
  input.className = "settings-toggle-input";
  input.id = `settings-${id}`;
  input.checked = checked;
  input.addEventListener("change", () => onChange(input.checked));
  input.addEventListener("click", (event) => event.stopPropagation());

  const visual = el("span", "settings-toggle", "");
  visual.setAttribute("aria-hidden", "true");
  const control = el("div", "settings-row-control", "");
  control.append(input, visual);

  const row = baseRow(icon, label, { labelFor: input.id });
  row.append(control);
  row.addEventListener("click", (event) => {
    if (event.target === input) return;
    input.checked = !input.checked;
    onChange(input.checked);
  });
  return row;
}

function selectRow<T extends string>(
  id: string,
  icon: string,
  label: string,
  value: T,
  options: readonly (readonly [T, string])[],
  onChange: (value: T) => void,
): HTMLElement {
  const select = document.createElement("select");
  select.className = "settings-select";
  select.id = `settings-${id}`;
  select.setAttribute("aria-labelledby", `settings-${id}-title`);
  select.replaceChildren(...options.map(([optionValue, optionLabel]) => {
    const option = document.createElement("option");
    option.value = optionValue;
    option.textContent = optionLabel;
    return option;
  }));
  select.value = value;
  select.addEventListener("change", () => onChange(select.value as T));

  const control = el("div", "settings-row-control", "");
  control.append(select);
  const row = baseRow(icon, label, { titleId: `settings-${id}-title` });
  row.append(control);
  return row;
}

function baseRow(icon: string, title: string, options?: { readonly labelFor?: string; readonly titleId?: string }): HTMLElement {
  const row = el("div", "settings-row", "");
  const text = el("div", "settings-row-text", "");
  if (options?.labelFor) {
    const label = document.createElement("label");
    label.className = "settings-row-title";
    label.htmlFor = options.labelFor;
    label.textContent = title;
    text.append(label);
  } else {
    const titleEl = el("div", "settings-row-title", title);
    if (options?.titleId) titleEl.id = options.titleId;
    text.append(titleEl);
  }
  row.append(el("div", "settings-icon-tile", icon), text);
  return row;
}

function segmentedControl<T extends string>(
  options: readonly (readonly [T, string])[],
  value: T,
  onChange: (value: T) => void,
  name: string,
): HTMLElement {
  const group = el("div", "settings-segmented", "");
  group.setAttribute("role", "group");
  group.replaceChildren(...options.map(([optionValue, optionLabel]) => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "settings-segment";
    button.textContent = optionLabel;
    button.setAttribute("aria-pressed", String(optionValue === value));
    button.addEventListener("click", () => onChange(optionValue));
    return button;
  }));
  group.setAttribute("aria-label", name);
  return group;
}

function languageOptions(): readonly (readonly [UserSettings["language"], string])[] {
  return [["zh", "简"], ["zh-Hant", "繁"], ["en", "EN"], ["th", "ไทย"]];
}

function calendarTypeOptions(): readonly (readonly [UserSettings["calendarType"], string])[] {
  return [["iso8601", t("国际标准")], ["us", t("美式")], ["arabic", t("阿拉伯")], ["hebrew", t("希伯来")]];
}

function actionIconModeOptions(): readonly (readonly [UserSettings["actionIconMode"], string])[] {
  return [["date", t("日期方块")], ["emoji", t("表情符号")], ["moonPhase", t("月相图标")]];
}

function getExtensionVersion(): string {
  if (typeof chrome !== "undefined" && chrome.runtime?.getManifest) {
    return `v${chrome.runtime.getManifest().version}`;
  }
  return "v2.0";
}

function el<K extends keyof HTMLElementTagNameMap>(tag: K, className: string, text: string): HTMLElementTagNameMap[K] {
  const item = document.createElement(tag);
  item.className = className;
  item.textContent = text;
  return item;
}
