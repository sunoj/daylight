# @daylight/holidays-ical

Cloudflare Pages that serves legal-holiday **iCal** feeds for the Daylight
clients, so the app doesn't depend on third-party `.ics` URLs staying up.

## Routes (Pages Function `functions/[region].ts`)

| URL | Source |
|-----|--------|
| `/cn.ics` (or `/cn`) | [holiday-cn](https://github.com/NateScarlet/holiday-cn) via jsDelivr — off-days and adjusted workdays, surrounding 3 years |

Only mainland China is hosted here — it has no official iCal feed. Regions that
do are used directly by the client and are **not** proxied:

- Hong Kong → GovHK official `https://www.1823.gov.hk/common/ical/tc.ics`
- Thailand → `https://www.officeholidays.com/ics/thailand`

Responses are `text/calendar` cached ~24h.

Events include `X-DAYLIGHT-DAY-TYPE:HOLIDAY` or `WORKDAY`. Workday summaries also
include `（调休上班）` so other iCal clients and older Daylight versions can read
the distinction. Updated clients preserve the typed value and show a workday badge.
The clients request `cn.ics?v=2` to bypass previously cached holiday-only responses.
Existing subscriptions should be refreshed once after upgrading.

## Deploy

```bash
cd apps/holidays-ical
yarn install                 # from repo root; installs wrangler
npx wrangler login           # once, interactive
yarn deploy                  # → wrangler pages deploy public --project-name daylight-holidays
```

First deploy creates the `daylight-holidays` project; the feeds are then at
`https://holidays.mings.work/cn.ics` (the project's own
`daylight-holidays.pages.dev` keeps serving them too, which is what already-released
builds still request). Custom domains are managed in the
Cloudflare dashboard if desired, then update the preset URLs in
`apps/mac-menubar/.../Holidays/HolidayService.swift`.

## Local dev

```bash
yarn dev                     # wrangler pages dev, serves functions locally
curl http://localhost:8788/cn.ics
```
