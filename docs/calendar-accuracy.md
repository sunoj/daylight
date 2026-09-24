# Calendar Accuracy Audit (2026-07)

Scope: the shared lunar-calendar and solar-term core in
`packages/core-calendar` (TypeScript, Chrome client) and its native port in
`apps/mac-menubar/Sources/DaylightMenuBar/LunarCalendar.swift` (macOS client),
plus the moon-phase approximation used for icons.

## Method

Every value for every day from 1949-01-29 through 2100-12-31 (55,489 days) was
compared against three independent references:

1. **astronomy-engine** (vendored at `src/lib/Astronomy.js`): solar term
   instants as apparent solar longitude crossings of 15° multiples, and new
   moon instants, both read in UTC+8 as required by the official Chinese
   calendar definition (GB/T 33661-2017).
2. **lunar-javascript** (寿星天文历-grade ephemeris, aligned with Purple
   Mountain Observatory publications).
3. **ICU** via Node's `Intl.DateTimeFormat` with the `chinese` calendar.

The two ephemerides agree on **all 3,648 solar term dates** in range, which is
the ground truth the term table is generated from.

## Findings and fixes

- **Solar terms (TypeScript)** — the 1900-epoch linear formula was wrong on
  **170 of 3,648** term dates (including 雨水 2026-02-18, shown as 02-19).
  Replaced by a generated day table
  (`packages/core-calendar/src/solar-term-table.ts`, regenerate with
  `packages/core-calendar/tools/generate-solar-term-table.ts`). The linear
  formula remains only as an out-of-range (~±1 day) fallback for distant
  calendar browsing.
- **Solar terms (Swift)** — the 公式法 + UTC+8-read fallback combination was
  wrong on **910 of 3,648** dates (integer truncation at year 2000, stale
  century constants, and a fallback that read the linear formula in UTC+8
  while TypeScript read it in UTC). Replaced with the same generated table;
  the fallback now matches TypeScript byte-for-byte.
- **Lunar table errors** — two entries of the widely circulated 1949–2100
  packed table are astronomically wrong and were corrected in all three copies
  (core-calendar constants, Swift, legacy `src/lib/SolarToLunar.ts`):
  - **1996**: `0x055c0 → 0x05ac0`. Months 5–8 are 30/29/30/29 days; 六月初一
    is 1996-07-16 (new moon 00:15 CST) and 中秋 八月十五 is 1996-09-27.
  - **2060**: `0x0a2e0 → 0x092e0`. 三月 has 29 days; 四月初一 is 2060-04-30
    (new moon 18:11 CST, unambiguous).
- **Swift leap months** — the Swift port labelled the leap month as the
  following month and never emitted the 闰 prefix (e.g. 2025-07-25 showed
  七月初一 instead of 闰六月初一). Fixed; `monthName` now carries 闰.
- **Dates before 1949-01-29** — both ports returned garbage for the first 28
  days of 1949 (`初undefined`). They now return an explicit error/nil. Solar
  terms remain available for those days (`getSolarTerm` in TypeScript,
  `LunarCalendar.solarTerm(for:)` in Swift).
- **Moon phase** — the mean-synodic approximation drifted up to ±0.97 days
  (wrong 8-bucket phase icon on ~10% of days). Both ports now compute the true
  sun–moon elongation with the truncated Meeus series: max drift ≈ 0.03 days,
  bucket mismatch ≈ 0.2% (only when the instant sits on a bucket boundary).

After the fixes, the TypeScript and Swift implementations were dumped for the
full range and are **byte-identical on all 55,489 days** (lunar year/month/day
names and solar terms).

## Adjudicated reference disagreements (no action needed)

ICU's chinese calendar disagrees with this implementation on a handful of
month boundaries where the astronomical new moon falls within minutes of CST
midnight. In every case the packed table matches both the astronomical instant
and the published calendar, so ICU is not treated as authoritative:

- 初一 boundaries: 1954-02-03 (春节), 1955-02-22, 1999-01-17, 2012-08-17,
  2018-11-08, 2027-02-06 (春节), 2030-02-03 (春节), 2070-03-12.
- Leap month placement 1987: ICU says 闰七月; the published calendar (and this
  implementation) has 闰六月.

**2057-09**: the new moon falls at ≈ 2057-09-29 00:00:44 CST per
astronomy-engine (初一 = 09-29, what this implementation and ICU produce) but
just before midnight per lunar-javascript (初一 = 09-28). The instant is
within ΔT extrapolation uncertainty and no official publication exists yet;
this is the one knowingly ambiguous month in the supported range.

## Invariants to keep

- `SOLAR_TERM_TABLE` in TypeScript and `termTable` in Swift must stay
  byte-identical; both come from the generator tool.
- `LUNAR_YEAR_DATA` (TS), `yearData` (Swift), and `lunarYearArr` (legacy) must
  stay in sync, including the 1996/2060 corrections.
- Golden tests covering all of the above live in
  `packages/core-calendar/tests/core-calendar.test.ts` and
  `apps/mac-menubar/Tests/DaylightMenuBarKitTests/LunarCalendarTests.swift`.
