import assert from "node:assert/strict";
import { resolveIconColors, resolveToolbarTheme } from "../src/icon-theme";

function testResolveToolbarTheme(): void {
  assert.equal(resolveToolbarTheme(false), "light");
  assert.equal(resolveToolbarTheme(true), "dark");
}

function testResolveIconColors(): void {
  assert.equal(resolveIconColors("light").foreground, "#1B1B1A");
  assert.equal(resolveIconColors("dark").foreground, "#ECEBE7");
  assert.equal(resolveIconColors("unknown").foreground, "#8A8984");
}

testResolveToolbarTheme();
testResolveIconColors();
console.log("icon-theme.test.ts: ok");
