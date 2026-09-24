/**
 * Diary thought timeline rendering for popup and detail screens.
 * Exports: renderDiaryTimeline, thoughtsForTimelineDisplay
 * Deps: domain diary thoughts, locale, diary time labels
 */

import type { DiaryThought } from "@daylight/domain";
import { sortDiaryThoughtsOldestFirst } from "@daylight/domain";
import { formatDiaryThoughtTime } from "./diary-time";
import { t } from "./locale";

export interface DiaryTimelineHandlers {
  readonly onDeleteThought: (id: string) => void;
  readonly onToggleThought: (id: string) => void;
}

export function thoughtsForTimelineDisplay(thoughts: readonly DiaryThought[]): readonly DiaryThought[] {
  return sortDiaryThoughtsOldestFirst(thoughts);
}

export function renderDiaryTimeline(
  thoughts: readonly DiaryThought[],
  handlers: DiaryTimelineHandlers,
): HTMLElement | null {
  if (thoughts.length === 0) return null;
  let armedThoughtId: string | null = null;
  let armedDeleteButton: HTMLButtonElement | null = null;

  const list = el("div", "diary-timeline", "");
  list.replaceChildren(
    ...thoughtsForTimelineDisplay(thoughts).map((thought) => renderThoughtRow(thought, handlers, {
      armedThoughtId: () => armedThoughtId,
      setArmed: (id, button) => {
        armedDeleteButton?.classList.remove("armed");
        armedDeleteButton?.setAttribute("aria-label", t("删除"));
        if (armedDeleteButton) armedDeleteButton.textContent = "×";
        armedThoughtId = id;
        armedDeleteButton = button;
        if (button) {
          button.classList.add("armed");
          button.textContent = "✓";
          button.setAttribute("aria-label", t("确认删除"));
        }
      },
      clearArmed: () => {
        armedDeleteButton?.classList.remove("armed");
        armedDeleteButton?.setAttribute("aria-label", t("删除"));
        if (armedDeleteButton) armedDeleteButton.textContent = "×";
        armedThoughtId = null;
        armedDeleteButton = null;
      },
    })),
  );
  const scroll = el("div", "diary-timeline-scroll", "");
  scroll.replaceChildren(list);
  return scroll;
}

interface DeleteArmState {
  readonly armedThoughtId: () => string | null;
  readonly setArmed: (id: string | null, button: HTMLButtonElement | null) => void;
  readonly clearArmed: () => void;
}

function renderThoughtRow(
  thought: DiaryThought,
  handlers: DiaryTimelineHandlers,
  deleteArm: DeleteArmState,
): HTMLElement {
  const row = el("div", "diary-thought", "");
  if (thought.done !== undefined) row.classList.add("diary-thought-todo");
  if (thought.done === true) row.classList.add("diary-thought-done");

  const timeLabel = formatDiaryThoughtTime(thought.createdAt);
  const time = el("span", "diary-thought-time", timeLabel === "just-now" ? t("刚刚") : timeLabel);
  const text = el("span", "diary-thought-text", thought.content);

  const children: HTMLElement[] = [time];
  if (thought.done !== undefined) {
    const toggle = document.createElement("button");
    toggle.type = "button";
    toggle.className = "diary-thought-toggle";
    toggle.setAttribute("aria-label", thought.content);
    toggle.setAttribute("role", "checkbox");
    toggle.setAttribute("aria-checked", String(thought.done));
    toggle.textContent = thought.done ? "☑" : "☐";
    toggle.addEventListener("click", () => handlers.onToggleThought(thought.id));
    children.push(toggle);
  }
  children.push(text);

  const remove = document.createElement("button");
  remove.type = "button";
  remove.className = "diary-thought-delete";
  remove.title = t("删除");
  remove.setAttribute("aria-label", t("删除"));
  remove.textContent = "×";
  remove.addEventListener("click", () => {
    if (deleteArm.armedThoughtId() === thought.id) {
      deleteArm.clearArmed();
      handlers.onDeleteThought(thought.id);
      return;
    }
    deleteArm.setArmed(thought.id, remove);
  });
  children.push(remove);

  row.replaceChildren(...children);
  return row;
}

function el<K extends keyof HTMLElementTagNameMap>(tag: K, className: string, text: string): HTMLElementTagNameMap[K] {
  const item = document.createElement(tag);
  item.className = className;
  item.textContent = text;
  return item;
}
