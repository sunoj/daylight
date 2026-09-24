/**
 * About, FAQ, and changelog overlay renderer.
 * Exports: renderAboutPanel
 * Deps: locale, Chrome manifest version
 */

import { t } from "./locale";

type InfoTab = "about" | "faq" | "changelog";

export function renderAboutPanel(): HTMLElement {
  const panel = el("section", "info-panel", "");
  const tabs = el("div", "info-tabs", "");
  const content = el("div", "info-content", "");
  let activeTab: InfoTab = "about";

  const rerender = (): void => {
    tabs.replaceChildren(
      tabButton("about", t("概览"), activeTab, () => { activeTab = "about"; rerender(); }),
      tabButton("faq", t("常见问题"), activeTab, () => { activeTab = "faq"; rerender(); }),
      tabButton("changelog", t("最近更新"), activeTab, () => { activeTab = "changelog"; rerender(); }),
    );
    content.replaceChildren(renderTab(activeTab));
  };

  panel.replaceChildren(tabs, content);
  rerender();
  return panel;
}

function renderTab(tab: InfoTab): HTMLElement {
  if (tab === "faq") return renderFaq();
  if (tab === "changelog") return renderChangelog();
  return renderAbout();
}

function renderAbout(): HTMLElement {
  const wrap = el("div", "info-body", "");
  const list = el("dl", "info-meta-list", "");
  list.replaceChildren(
    el("dt", "info-meta-label", t("版本")),
    el("dd", "info-meta-value", getExtensionVersion()),
    el("dt", "info-meta-label", t("许可证")),
    el("dd", "info-meta-value", "GPL-2.0"),
    el("dt", "info-meta-label", t("联系")),
    el("dd", "info-meta-value", "hi@mings.work"),
  );
  wrap.replaceChildren(el("p", "info-paragraph", t("查询农历、二十四节气、公共假日与月相的日历扩展。")), list);
  return wrap;
}

function renderFaq(): HTMLElement {
  const list = el("ul", "info-faq", "");
  list.replaceChildren(
    faqItem(t("问：可以改每周从哪天开始吗？"), t("答：在设置里切换日历类型，即可决定每周的第一天。")),
    faqItem(t("问：昼间把数据存在哪里？"), t("答：你添加的日期标记和日记只保存在本机。")),
    faqItem(t("问：日历信息从哪里来？"), t("答：公共假日来自同步的远程来源；农历、节气与月相都在本地计算。")),
  );
  return list;
}

function renderChangelog(): HTMLElement {
  const list = el("ul", "info-changelog", "");
  const entry = el("li", "info-changelog-entry", "");
  entry.replaceChildren(
    el("div", "info-changelog-head", `${getExtensionVersion()} · ${t("体验版")}`),
    el("div", "info-changelog-detail", t("日记支持 [] 待办，删除改为二次确认，输入框按所选日期提示；移除双日历视图。")),
  );
  list.replaceChildren(entry);
  return list;
}

function faqItem(question: string, answer: string): HTMLElement {
  const item = el("li", "info-faq-item", "");
  item.replaceChildren(el("p", "info-faq-q", question), el("p", "info-faq-a", answer));
  return item;
}

function tabButton(tab: InfoTab, label: string, active: InfoTab, onSelect: () => void): HTMLButtonElement {
  const button = document.createElement("button");
  button.type = "button";
  button.className = active === tab ? "info-tab active" : "info-tab";
  button.textContent = label;
  button.addEventListener("click", onSelect);
  return button;
}

function getExtensionVersion(): string {
  if (typeof chrome !== "undefined" && chrome.runtime?.getManifest) {
    return chrome.runtime.getManifest().version;
  }
  return "0.0.0";
}

function el<K extends keyof HTMLElementTagNameMap>(tag: K, className: string, text: string): HTMLElementTagNameMap[K] {
  const item = document.createElement(tag);
  item.className = className;
  item.textContent = text;
  return item;
}
