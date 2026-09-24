/**
 * Fixed header + scrollable body shell for non-calendar popup screens.
 * Exports: renderScreenShell
 * Deps: locale
 */

import { t } from "./locale";

export function renderScreenShell(title: string, onBack: () => void, body: HTMLElement): HTMLElement {
  const shell = el("div", "screen", "");
  const header = el("header", "screen-header", "");
  const back = document.createElement("button");
  back.type = "button";
  back.className = "screen-back";
  back.textContent = "‹";
  back.title = t("返回");
  back.setAttribute("aria-label", t("返回"));
  back.addEventListener("click", onBack);
  const titleEl = el("div", "screen-title", title);
  header.replaceChildren(back, titleEl);

  const scroll = el("div", "screen-body", "");
  scroll.append(body);
  shell.replaceChildren(header, scroll);
  return shell;
}

function el<K extends keyof HTMLElementTagNameMap>(tag: K, className: string, text: string): HTMLElementTagNameMap[K] {
  const item = document.createElement(tag);
  item.className = className;
  item.textContent = text;
  return item;
}
