/**
 * Cloudflare Pages Function: serve legal-holiday iCal feeds for the Daylight
 * clients. Route: /cn(.ics).
 * CN includes both off-days and adjusted workdays from holiday-cn.
 * Responses are cached ~1 day.
 */

interface HolidayDay {
  readonly name: string;
  readonly date: string; // YYYY-MM-DD
  readonly isOffDay: boolean;
}

interface HolidayCnYear {
  readonly year: number;
  readonly days: readonly HolidayDay[];
}

const CACHE_HEADERS = {
  "content-type": "text/calendar; charset=utf-8",
  "cache-control": "public, max-age=86400",
  "access-control-allow-origin": "*",
};

export const onRequestGet: PagesFunction = async (context) => {
  const raw = String((context.params as { region: string }).region);
  const region = raw.replace(/\.ics$/i, "").toLowerCase();
  // Only regions WITHOUT an official/recommended external iCal are hosted here.
  // Mainland China has none (国务院 publishes announcements, not a feed), so it
  // is generated from the maintained holiday-cn dataset. HK (GovHK) and TH
  // (officeholidays.com) use their own feeds directly in the client.
  if (region !== "cn") {
    return new Response("Unknown region", { status: 404 });
  }
  try {
    const year = new Date().getUTCFullYear();
    return icsResponse(await buildChina([year - 1, year, year + 1]));
  } catch {
    return new Response("Upstream fetch failed", { status: 502 });
  }
};

async function buildChina(years: readonly number[]): Promise<string> {
  const events: string[] = [];
  for (const year of years) {
    const url = `https://cdn.jsdelivr.net/gh/NateScarlet/holiday-cn@master/${year}.json`;
    const response = await fetch(url, { cf: { cacheTtl: 86400, cacheEverything: true } });
    if (!response.ok) continue;
    const payload = (await response.json()) as HolidayCnYear;
    for (const day of payload.days) {
      const type = day.isOffDay ? "HOLIDAY" : "WORKDAY";
      // Keep the type readable in calendar apps that ignore our extension.
      const name = day.isOffDay ? day.name : `${day.name}（调休上班）`;
      events.push(vevent(day.date, name, "cn", type));
    }
  }
  return calendar("昼间 · 中国大陆法定节假日", events);
}

function vevent(date: string, name: string, region: string, type: "HOLIDAY" | "WORKDAY"): string {
  const start = date.replace(/-/g, "");
  const end = nextDay(date);
  return [
    "BEGIN:VEVENT",
    `UID:${start}-${region}@daylight.holidays`,
    "DTSTAMP:19700101T000000Z",
    `DTSTART;VALUE=DATE:${start}`,
    `DTEND;VALUE=DATE:${end}`,
    `SUMMARY:${escapeText(name)}`,
    `X-DAYLIGHT-DAY-TYPE:${type}`,
    "TRANSP:TRANSPARENT",
    "END:VEVENT",
  ].join("\r\n");
}

function nextDay(date: string): string {
  const [y, m, d] = date.split("-").map(Number);
  const next = new Date(Date.UTC(y, m - 1, d + 1));
  const yyyy = next.getUTCFullYear();
  const mm = String(next.getUTCMonth() + 1).padStart(2, "0");
  const dd = String(next.getUTCDate()).padStart(2, "0");
  return `${yyyy}${mm}${dd}`;
}

function calendar(name: string, events: readonly string[]): string {
  return [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//Daylight//Holidays//CN",
    "CALSCALE:GREGORIAN",
    `X-WR-CALNAME:${escapeText(name)}`,
    ...events,
    "END:VCALENDAR",
    "",
  ].join("\r\n");
}

function escapeText(value: string): string {
  return value.replace(/([,;\\])/g, "\\$1").replace(/\n/g, "\\n");
}

function icsResponse(body: string): Response {
  return new Response(body, { headers: CACHE_HEADERS });
}
