/** The hosted feed and client parser must preserve adjusted workdays end to end. */
import assert from "node:assert/strict";
import { onRequestGet } from "../../../apps/holidays-ical/functions/[region]";
import { parseHolidayIcs } from "../src/holiday-ical";

const originalFetch = globalThis.fetch;
const year = new Date().getUTCFullYear();
globalThis.fetch = async (url) => {
  if (!String(url).endsWith(`/${year}.json`)) return new Response("", { status: 404 });
  return Response.json({ year, days: [
    { date: `${year}-10-01`, name: "国庆节", isOffDay: true },
    { date: `${year}-10-10`, name: "国庆节", isOffDay: false },
  ] });
};
try {
  const response = await onRequestGet({ params: { region: "cn.ics" } } as never);
  assert.equal(response.status, 200);
  const body = await response.text();
  assert.match(body, /SUMMARY:国庆节（调休上班）/);
  const days = parseHolidayIcs(body).days;
  assert.equal(days.length, 2);
  assert.equal(days[0]?.type, "holiday");
  assert.equal(days[1]?.type, "workday");
  assert.equal(days[1]?.date, `${year}-10-10`);
  assert.equal(days[1]?.name, "国庆节");
} finally {
  globalThis.fetch = originalFetch;
}

const mixed = parseHolidayIcs([
  "BEGIN:VCALENDAR", "BEGIN:VEVENT", "DTSTART;VALUE=DATE:20261010",
  "X-DAYLIGHT-DAY-TYPE:WORKDAY", "SUMMARY:国庆节（调休上班）", "END:VEVENT",
  "BEGIN:VEVENT", "DTSTART;VALUE=DATE:20261011", "SUMMARY:Ordinary external event", "END:VEVENT",
  "BEGIN:VEVENT", "DTSTART;VALUE=DATE:20261012", "X-DAYLIGHT-DAY-TYPE:UNKNOWN", "END:VEVENT",
  "END:VCALENDAR",
].join("\r\n"));
assert.deepEqual(mixed.days.map(day => day.type), ["workday", "holiday", "holiday"]);
