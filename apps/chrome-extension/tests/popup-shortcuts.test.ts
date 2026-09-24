/**
 * Popup keyboard shortcut resolution tests.
 * Covers: action mapping for each binding, typing-target guard, shortcut help rows
 * Deps: node assert, popup shortcut table
 */

import assert from "node:assert/strict";
import { installTestDom } from "./test-dom";
import {
  SHORTCUT_BINDINGS,
  isTypingTarget,
  resolveShortcutAction,
  shortcutHelpRows,
  type ShortcutAction,
} from "../src/popup-shortcuts";

installTestDom();

function keyEvent(
  type: "keydown" | "keyup",
  init: KeyboardEventInit & { readonly target?: EventTarget | null },
): KeyboardEvent {
  const event = new KeyboardEvent(type, init);
  if (init.target !== undefined) Object.defineProperty(event, "target", { value: init.target });
  return event;
}

function textareaTarget(): EventTarget {
  return document.createElement("textarea");
}

assert.equal(isTypingTarget(textareaTarget()), true);

const expectedActions: Record<string, ShortcutAction> = {
  ArrowLeft: "prevDay",
  ArrowRight: "nextDay",
  ArrowUp: "prevMonth",
  ArrowDown: "nextMonth",
  d: "openDetail",
  m: "backToCurrentMonth",
  o: "backToCurrentMonth",
  s: "openSettings",
  c: "openSettings",
  h: "showShortcutHelp",
  w: "goBack",
};

for (const [codeOrKey, action] of Object.entries(expectedActions)) {
  const isArrow = codeOrKey.startsWith("Arrow");
  const event = keyEvent("keyup", isArrow ? { code: codeOrKey, key: codeOrKey } : { key: codeOrKey, shiftKey: false });
  assert.equal(resolveShortcutAction(event), action, codeOrKey);
}

const shiftHelp = keyEvent("keyup", { key: "?", shiftKey: true });
assert.equal(resolveShortcutAction(shiftHelp), "showShortcutHelp");

const typing = keyEvent("keyup", { key: "d", shiftKey: false, target: textareaTarget() });
assert.equal(resolveShortcutAction(typing), null);

assert.equal(shortcutHelpRows().length, SHORTCUT_BINDINGS.length);
for (const binding of SHORTCUT_BINDINGS) {
  const row = shortcutHelpRows().find((item) => item.labelKey === binding.labelKey);
  assert.ok(row, binding.labelKey);
  assert.deepEqual(row?.displays, binding.displays);
}
