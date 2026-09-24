/**
 * Shortcut help overlay render tests.
 * Covers: shortcut reference lists every binding from the shared table
 * Deps: node assert, shortcut help renderer, popup shortcut table
 */

import assert from "node:assert/strict";
import { installTestDom } from "./test-dom";
import { SHORTCUT_BINDINGS } from "../src/popup-shortcuts";
import { renderShortcutHelpList } from "../src/shortcut-help-render";

installTestDom();

const panel = renderShortcutHelpList();
const rows = panel.querySelectorAll(".shortcut-row");
assert.equal(rows.length, SHORTCUT_BINDINGS.length);

for (const binding of SHORTCUT_BINDINGS) {
  const match = [...rows].find((row) => row.querySelector(".shortcut-label")?.textContent === binding.labelKey);
  assert.ok(match, binding.labelKey);
  const keys = [...match?.querySelectorAll(".shortcut-key") ?? []].map((node) => node.textContent);
  assert.deepEqual(keys, [...binding.displays]);
}
