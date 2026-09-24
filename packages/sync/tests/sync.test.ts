/**
 * Sync smoke tests for typed remote payload handling.
 * Covers: default config parsing and public calendar repository replacement
 * Deps: node assert, sync and storage public APIs
 */

import assert from "node:assert/strict";
import { ok } from "@daylight/domain";
import { createMemoryRepositories } from "@daylight/storage";
import { parseDefaultConfigPayload, parseHolidayIcs, resolvedCustomHolidayName, syncPublicCalendar } from "../src/index";
import type { HttpClient } from "../src/index";

const config = parseDefaultConfigPayload({
  sources: [{ kind: "public-calendar", url: "https://example.test/public-calendar.json", version: "2026" }],
});
assert.equal(config.ok, true);

const httpClient: HttpClient = {
  async getJson() {
    return ok({
      status: 200,
      body: [{ date: "2026-01-01", type: "holiday", name: "New Year", isImportant: true }],
    });
  },
};

const repos = createMemoryRepositories();
if (!config.ok) throw new Error("Config parsing failed");
const source = config.value.sources[0];
if (!source) throw new Error("Missing source");

const result = await syncPublicCalendar({
  source,
  httpClient,
  repository: repos.publicCalendar,
});
assert.equal(result.ok, true);

const stored = await repos.publicCalendar.listPublicDays();
assert.equal(stored.ok, true);
if (stored.ok) assert.equal(stored.value[0]?.name, "New Year");

const multiDay = parseHolidayIcs([
  "BEGIN:VCALENDAR",
  "X-WR-CALNAME:Example",
  "BEGIN:VEVENT",
  "SUMMARY:Country: Spring Break",
  "DTSTART;VALUE=DATE:20260401",
  "DTEND;VALUE=DATE:20260403",
  "END:VEVENT",
  "BEGIN:VEVENT",
  "SUMMARY:Country: Founding Day",
  "DTSTART;VALUE=DATE:20260405",
  "END:VEVENT",
  "END:VCALENDAR",
].join("\n"));
assert.equal(multiDay.name, "Example");
assert.deepEqual(multiDay.days.map((day) => day.date), ["2026-04-01", "2026-04-02", "2026-04-05"]);
assert.deepEqual(multiDay.days.map((day) => day.name), ["Spring Break", "Spring Break", "Founding Day"]);

// RFC 5545 edge cases: folded lines, escaped TEXT, and DTEND <= DTSTART.
const edgeCases = parseHolidayIcs([
  "BEGIN:VCALENDAR",
  "X-WR-CALNAME:Fest\\, Days",
  "BEGIN:VEVENT",
  "SUMMARY:The day following the Chinese Mid-Autumn Fe",
  " stival\\, observed",
  "DTSTART;VALUE=DATE:20261001",
  "END:VEVENT",
  "BEGIN:VEVENT",
  "SUMMARY:Inverted range",
  "DTSTART;VALUE=DATE:20261005",
  "DTEND;VALUE=DATE:20261005",
  "END:VEVENT",
  "END:VCALENDAR",
].join("\r\n"));
assert.equal(edgeCases.name, "Fest, Days");
assert.deepEqual(edgeCases.days.map((day) => [day.date, day.name]), [
  ["2026-10-01", "The day following the Chinese Mid-Autumn Festival, observed"],
  ["2026-10-05", "Inverted range"],
]);

const foldedName = parseHolidayIcs([
  "BEGIN:VCALENDAR",
  "X-WR-CALNAME:Hong Kong",
  "  Public Holidays",
  "BEGIN:VEVENT",
  "SUMMARY:Holiday",
  "DTSTART:20260101",
  "END:VEVENT",
  "END:VCALENDAR",
].join("\r\n"));
assert.equal(foldedName.name, "Hong Kong Public Holidays");

const mixedPrefix = parseHolidayIcs([
  "BEGIN:VEVENT",
  "SUMMARY:Country: One",
  "DTSTART:20260101",
  "END:VEVENT",
  "BEGIN:VEVENT",
  "SUMMARY:Other: Two",
  "DTSTART:20260102",
  "END:VEVENT",
].join("\n"));
assert.deepEqual(mixedPrefix.days.map((day) => day.name), ["Country: One", "Other: Two"]);

assert.equal(resolvedCustomHolidayName({
  id: "custom-1",
  sourceId: "custom",
  customURL: "https://calendar.example/feed.ics",
  colorId: "rust",
  enabled: true,
  name: "Typed",
}, "Imported", "https://calendar.example/feed.ics"), "Typed");
assert.equal(resolvedCustomHolidayName({
  id: "custom-2",
  sourceId: "custom",
  customURL: "https://calendar.example/feed.ics",
  colorId: "rust",
  enabled: true,
  name: "",
}, "Imported", "https://calendar.example/feed.ics"), "Imported");
assert.equal(resolvedCustomHolidayName({
  id: "custom-3",
  sourceId: "custom",
  customURL: "https://calendar.example/feed.ics",
  colorId: "rust",
  enabled: true,
  name: "",
}, null, "https://calendar.example/feed.ics"), "calendar.example");
