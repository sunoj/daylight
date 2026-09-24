/**
 * Holiday iCal presets and parser shared by clients.
 * Exports: holiday sources, URL/name resolution, and iCal parsing
 * Deps: shared domain holiday and public-day models
 */

import type { HolidaySubscription, LocalDateKey, PublicCalendarDay } from "@daylight/domain";

export type HolidaySourceCount =
  | { readonly kind: "daysPerYear"; readonly value: number }
  | { readonly kind: "days"; readonly value: number }
  | { readonly kind: "unknown" }
  | { readonly kind: "none" };

export interface HolidaySource {
  readonly id: string;
  readonly name: string;
  readonly detail: string;
  readonly count: HolidaySourceCount;
  readonly url?: string;
}

export interface HolidayFeed {
  readonly name: string | null;
  readonly days: readonly PublicCalendarDay[];
}

const FEED_BASE = "https://holidays.mings.work";

export const HOLIDAY_SOURCES: readonly HolidaySource[] = [
  { id: "cn", name: "中国大陆", detail: "国务院办公厅 · 官方公告", count: { kind: "daysPerYear", value: 13 }, url: `${FEED_BASE}/cn.ics?v=2` },
  { id: "hk", name: "中国香港特别行政区", detail: "GovHK 官方日历", count: { kind: "days", value: 17 }, url: "https://www.1823.gov.hk/common/ical/tc.ics" },
  { id: "tw", name: "中国台湾", detail: "行政院人事行政总处", count: { kind: "unknown" } },
  { id: "th", name: "泰国", detail: "officeholidays.com", count: { kind: "unknown" }, url: "https://www.officeholidays.com/ics/thailand" },
  { id: "custom", name: "自定义 iCal 链接", detail: "粘贴任意 .ics 订阅地址", count: { kind: "none" } },
];

export function holidaySource(id: string): HolidaySource | undefined {
  return HOLIDAY_SOURCES.find((source) => source.id === id);
}

export function resolvedHolidayUrl(sourceId: string, customURL: string): string | null {
  if (sourceId === "custom") return clean(customURL) || null;
  return holidaySource(sourceId)?.url ?? null;
}

export function parseHolidayIcs(ics: string): HolidayFeed {
  return { name: parseHolidayCalendarName(ics), days: parseHolidayDays(ics) };
}

export function parseHolidayCalendarName(ics: string): string | null {
  for (const line of unfoldedLines(ics)) {
    if (propertyName(line) !== "X-WR-CALNAME") continue;
    const value = unescapeText(propertyValue(line)).trim();
    return value.length > 0 ? value : null;
  }
  return null;
}

export function resolvedCustomHolidayName(subscription: HolidaySubscription, calendarName: string | null, url: string): string {
  const typed = clean(subscription.name);
  if (typed) return typed;
  const imported = clean(calendarName ?? "");
  if (imported) return imported;
  return hostFromUrl(url) || "自定义 iCal 链接";
}

function parseHolidayDays(ics: string): readonly PublicCalendarDay[] {
  const days: PublicCalendarDay[] = [];
  const eventNames: (string | null)[] = [];
  let start: string | null = null;
  let end: string | null = null;
  let summary: string | null = null;
  let type: PublicCalendarDay["type"] = "holiday";
  for (const line of unfoldedLines(ics)) {
    if (line.startsWith("BEGIN:VEVENT")) { start = null; end = null; summary = null; type = "holiday"; }
    else if (propertyName(line) === "DTSTART") start = dateValue(line);
    else if (propertyName(line) === "DTEND") end = dateValue(line);
    else if (propertyName(line) === "SUMMARY") summary = unescapeText(propertyValue(line));
    else if (propertyName(line) === "X-DAYLIGHT-DAY-TYPE") {
      const value = propertyValue(line).trim().toLowerCase();
      type = value === "workday" || value === "observance" ? value : "holiday";
    }
    else if (line.startsWith("END:VEVENT") && start) {
      const name = type === "workday" ? summary?.replace(/（调休上班）$/, "") ?? null : summary;
      const expanded = expandHoliday(start, end, name, type);
      if (expanded.length > 0) { eventNames.push(summary); days.push(...expanded); }
    }
  }
  return stripSharedFeedPrefix(days, eventNames);
}

function unfoldedLines(ics: string): readonly string[] {
  const lines: string[] = [];
  for (const raw of ics.replace(/\r\n/g, "\n").split("\n")) {
    if ((raw.startsWith(" ") || raw.startsWith("\t")) && lines.length > 0) {
      const previous = lines[lines.length - 1] ?? "";
      lines[lines.length - 1] = previous + raw.slice(1);
    } else {
      lines.push(raw);
    }
  }
  return lines;
}

function propertyName(line: string): string {
  const colon = line.indexOf(":");
  const semicolon = line.indexOf(";");
  const end = [colon, semicolon].filter((index) => index >= 0).sort((a, b) => a - b)[0] ?? line.length;
  return line.slice(0, end).toUpperCase();
}

function propertyValue(line: string): string {
  const index = line.indexOf(":");
  return index >= 0 ? line.slice(index + 1) : "";
}

function dateValue(line: string): string | null {
  const digits = propertyValue(line).slice(0, 8);
  return /^\d{8}$/.test(digits) ? digits : null;
}

function expandHoliday(start: string, end: string | null, name: string | null, type: PublicCalendarDay["type"]): readonly PublicCalendarDay[] {
  const startTime = utcDay(start);
  if (startTime === null) return [];
  const endTime = end ? utcDay(end) : null;
  // A missing or malformed DTEND (including DTEND <= DTSTART) still marks the
  // start day instead of dropping the event.
  const stop = endTime !== null && endTime > startTime ? endTime : startTime + 86_400_000;
  const days: PublicCalendarDay[] = [];
  for (let time = startTime; time < stop && days.length <= 366; time += 86_400_000) {
    const date = new Date(time);
    const day = { date: date.toISOString().slice(0, 10) as LocalDateKey, type, isImportant: true };
    days.push(name === null ? day : { ...day, name });
  }
  return days;
}

function utcDay(yyyymmdd: string): number | null {
  if (!/^\d{8}$/.test(yyyymmdd)) return null;
  const year = Number(yyyymmdd.slice(0, 4));
  const month = Number(yyyymmdd.slice(4, 6));
  const day = Number(yyyymmdd.slice(6, 8));
  return Date.UTC(year, month - 1, day);
}

function stripSharedFeedPrefix(days: readonly PublicCalendarDay[], eventNames: readonly (string | null)[]): readonly PublicCalendarDay[] {
  if (eventNames.length < 2) return days;
  const first = eventNames[0];
  const marker = first?.indexOf(": ") ?? -1;
  if (!first || marker < 0) return days;
  const prefix = first.slice(0, marker + 2);
  if (!eventNames.every((name) => !!name && name.startsWith(prefix) && name.length > prefix.length)) return days;
  return days.map((day) => day.name?.startsWith(prefix) ? { ...day, name: day.name.slice(prefix.length) } : day);
}

// RFC 5545 TEXT unescaping: \\ \; \, \n (holiday names fold newlines to a space).
function unescapeText(value: string): string {
  return value.replace(/\\([\\;,nN])/g, (_, char: string) => (char === "n" || char === "N" ? " " : char));
}

function clean(value: string): string {
  return value.trim();
}

function hostFromUrl(url: string): string {
  const match = /^[a-z][a-z0-9+.-]*:\/\/([^/?#]+)/i.exec(url.trim());
  return match?.[1] ?? "";
}
