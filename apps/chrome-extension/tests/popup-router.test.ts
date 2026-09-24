/**
 * Popup screen router tests.
 * Covers: forward navigation targets and back-stack behavior
 * Deps: node assert, popup router
 */

import assert from "node:assert/strict";
import {
  CALENDAR_NAVIGATION,
  canGoBack,
  navigateTo,
  popScreen,
  pushScreen,
} from "../src/popup-router";

const calendar = { kind: "calendar" as const };
const settings = { kind: "settings" as const };
const holidays = { kind: "holidays" as const };
const detail = { kind: "detail" as const };
const shortcuts = { kind: "shortcuts" as const };

assert.deepEqual(navigateTo(CALENDAR_NAVIGATION, "settings"), {
  screen: settings,
  stack: [calendar],
});

assert.deepEqual(navigateTo(CALENDAR_NAVIGATION, "detail"), {
  screen: detail,
  stack: [calendar],
});

assert.deepEqual(
  pushScreen({ screen: settings, stack: [calendar] }, holidays),
  { screen: holidays, stack: [calendar, settings] },
);

const fromHolidays = { screen: holidays, stack: [calendar, settings] };
assert.deepEqual(popScreen(fromHolidays), { screen: settings, stack: [calendar] });
assert.deepEqual(popScreen({ screen: settings, stack: [calendar] }), CALENDAR_NAVIGATION);
assert.deepEqual(popScreen(CALENDAR_NAVIGATION), CALENDAR_NAVIGATION);

assert.equal(canGoBack(CALENDAR_NAVIGATION), false);
assert.equal(canGoBack({ screen: shortcuts, stack: [calendar] }), true);

assert.deepEqual(navigateTo(CALENDAR_NAVIGATION, "calendar"), CALENDAR_NAVIGATION);

console.log("popup-router.test.ts: ok");
