# macOS Menu Bar Progress

## Status as of 2026-08-21 — Date Detail and Marks Retired

The redundant Sol date-detail screen and its date-mark feature are retired. Sol
now keeps the selected day's holidays, system-calendar events, moon, and diary
timeline on the calendar screen, with existing `marks` data left untouched.

## Status as of 2026-08-19 — Luna/Sol, System Calendars, Diary Timeline, Performance

Test status: 130 passing (`swift test`), TypeScript typecheck and all rewrite
suites green, Chrome extension builds. Two standing invariants are currently
BROKEN and head the follow-up list: `Storage.swift` is 332 lines against the
300 ceiling, and `Panels/` holds 10 files where the convention is fewer than 10.

**The popover has two modes.** Luna is a compact 300pt month grid over a
fixed-dark agenda; Sol is the fuller 412pt calendar. Luna is the default, and
`UserSettings.uiMode` migrates the earlier `minimal`/`full` values so an
existing install keeps its choice. The two modes were drifting apart feature by
feature, so both now show system-calendar events, subscribed holidays, the moon
and the diary; Sol's screen reads grid → agenda → moon → diary.

**System calendars are read through EventKit, read-only,** with per-calendar
visibility stored as `hiddenCalendarIds` — hidden ids rather than enabled ones,
so a calendar created in Calendar.app later shows up instead of silently going
missing. Filtering happens in the predicate and the hidden set is part of the
query cache key, so hiding a calendar cannot serve a stale result.

**The diary is a timeline of thoughts, not one note per day.** It used to be
keyed by date, so a second thought silently overwrote the first. Entries are now
independent records with ids and creation times; existing per-day notes migrate
to that day's first thought keeping their timestamp. Both clients share the
model.

**One month grid's titles took 550ms.** `titleParts` runs per cell and every
call went back to the store, which decoded from `UserDefaults` each time — marks,
then the whole holiday dataset and settings for `publicDay`, the same two again
for `holidayHits`, and a third pass for the tooltip. On the order of a hundred
full JSON decodes per render, on the main thread, repeated for every selection
and month change. The store now caches decoded values and drops them on write.
`CalendarDayTitleFormatterPerformanceTests` holds the threshold.

Defects found by looking at the running app, not by tests — every one of these
passed a green suite:

- The popover rendered its contents TWICE. `render()` was not re-entrancy safe
  and the first EventKit access posts `EKEventStoreChanged` synchronously, so
  the change handler re-entered a render still in progress.
- Luna's today circle was smaller than the two-digit number it contained, and
  a variant sized per cell gave a day with events a different disc from one
  without. `LunaCellGeometryTests` measures it now.
- Day numbers sat at three different heights in one row, because cells with
  event dots had taller content than cells without and the whole thing was
  centred.
- The diary row's delete control chased the end of the sentence instead of
  holding the row's edge, from three nested layout mistakes: an unpinned scroll
  document, rows added to a `.leading` stack without a width pin, and baseline
  alignment applied to a row holding an `NSImageView`.
- The agenda reserved height from a `fittingSize` measured before layout, so it
  left dead space under the last event.
- Luna's footer inherited `NSStackView`'s 8pt default spacing, putting 19pt
  above its content against 10pt below.
- Closing the 3D moon or a day's detail always returned to Sol, whatever mode
  was active, because "which screen is home" was duplicated in four places.

## Roadmap

Ordered by what blocks users, not by effort.

1. **Restore the broken invariants.** Split `Storage.swift` below 300 lines and
   get `Panels/` under 10 files. Both were enforced on every change this cycle
   and then quietly breached by it.
2. **Ship the Chrome MV3 build.** `昼间日历` 0.3.0 builds and is MV3, but what
   is published is still the MV2 build from `src/`, which Chrome stopped running
   in July 2025 and whose listing the store purges on 2026-08-31 (see
   `chrome-extension-audit.md` §7). Shipping preserves the listing; the purge
   does not. Blockers: the feature gaps below, and no E2E coverage of the flows
   an update puts in front of existing users.
3. **Chrome parity gaps** against the published build: year/decade/century
   views, mark editing, diary export, the dark-mode setting.
4. **Verify launch-at-login for real.** `SMAppService` registration generally
   needs the app in `/Applications`, so the development build cannot confirm it.
   Requires a signed build from `scripts/release-macos.sh`.
5. **Frosted glass over a bright background.** The dark-mode translucency was
   only checked over a dark background; the alphas in `Palette` are the single
   knob if text washes out over a white window or a photo wallpaper.
6. **Configure the Sparkle feed.** `packaging/SparkleFeedURL.txt` is still
   empty, so auto-update has nowhere to point.
7. **Fill in the site's download link.** `apps/site` is deployed at
   `daylight-o1b.pages.dev`; `daylight.mings.work` needs one CNAME, and
   `MAC_DOWNLOAD_URL` is an empty launch blocker until a signed dmg exists.

## Status as of 2026-07-17 — Moon Dates, Holidays Rework, Solar-Term Icons

Test status: 60 passing (`swift test`), TypeScript typecheck + all three package
suites green. Every source file is under 300 lines (max: `Storage.swift` at 295)
and every module directory under 10 files.

**Moon panels showed today regardless of the date you opened them from.**
`Moon3DPanel`/`MoonPhasePanel` took no date and hardcoded `Date()`, and
`openMoon` carried none — only `DateDetailPanel.moonCard()` was correct.
`MoonObservationDateResolver` now holds the rule in one place: today keeps the
live instant so Alt/Az matches the real sky, any other date uses noon.

**Location is cached for 7 days.** Not a permission expiry — `install-local.sh`
ad-hoc signs (`codesign --sign -`) and `rm -rf`s the bundle, so the cdhash
changes every rebuild (verified) and TCC treats each build as a new app. A
signed release will not. The cache is worth having anyway; `.denied` never reads
it (the user revoked access deliberately) and clears it.

**Holiday subscriptions are multi-select with per-source colours.**
`holidaySource` → `[HolidaySubscription]`, days stored per subscription id, and
legacy single subscriptions migrate. The grid went MORE monochrome as a result:
the old red tint on the day number is gone; a holiday is now up to three muted
dots at the bottom of the cell, one per matching subscription. The detail page
lists them with source names, since two dots cannot say which feeds they are.
Feeds that prefix every event with the country ("Thailand: Songkran") get that
prefix stripped when — and only when — every event in the feed shares it.

**24 hand-drawn solar-term icons** (`SolarTermIconGlyphs`), phenological: the
四立 are one plant across the year, 春分/秋分 are the swallow returning and
leaving, and so on. Shown on the detail page, which previously never mentioned
the solar term at all.

Defects fixed, all found by looking at the running app rather than by tests:

- The location prompt rendered **blank**. `pillButton` pinned each pill's width
  to the panel before adding it; activating a constraint across views with no
  common ancestor throws, so layout aborted, `fittingSize` came back zero, and
  `sizeToFit`'s `max(height, 1)` turned the crash into a 1pt-tall popover.
- Then its buttons **still did not paint**: `radius: 999` — the pill idiom —
  reached CoreAnimation unclamped, which is undefined above half the bounds and
  silently drew nothing on a wide box. Square users of the idiom survived, which
  is why it looked fine everywhere else. `LayerColorView` clamps now.
- The selected holiday row painted **light-mode surface-2 under dark mode**: the
  colour was resolved at construction, before the view was in the hierarchy, so
  it inherited the app default. Same class as the constraint bug above.
- Filled buttons **stretched** instead of hugging (the design says
  `height 30, padding 0 15px`); `UI.filledButton` only centred its label.

Known follow-ups:
- The design specifies **7 status-bar fields**; we ship 6 — 节气 and 周数 are
  missing.
- `冬至` is the weakest of the 24 glyphs.
- The `AppDelegate.swift:42` Swift 6 `SendableClosureCaptures` warning predates
  this work.
- Lessons that are now enforced mechanically: icons are judged at their real
  24pt size (enlarged flatters them), no glyph exceeds 6 strokes, and no two
  glyphs may render identically — the first icon set shipped 夏至 pixel-identical
  to 立夏 with every per-term test green.

## Status as of 2026-07-16 — Roadmap Follow-ups, Design Conformance, 宜/忌 Removal

Cleared the follow-up list below, then fixed three defects found by visual QA.

Roadmap follow-ups, all done:

- **Oversized files split**, following the `PopoverViewController+*` extension
  convention: `DateDetailPanel` 376 → 261 + 124 (`+Sections`),
  `CalendarSettingsPanel` 313 → 226 + 92 (`+Rows`), `Components` 311 → 95 +
  `Controls` 188 + `ViewPrimitives` 71. Every source file is now under 300
  (max: `HolidaySubscriptionPanel` at 294).
- **Settings reset bug FIXED.** `UserSettings` relied on Swift's synthesized
  `Codable` init, which calls `decode()` (not `decodeIfPresent`) and throws on a
  missing key; `read()` swallowed it with `try?` and returned defaults, so
  adding a field silently reset every stored setting. It now has a custom
  `init(from:)` using `decodeIfPresent` for all fields, defaulting from one
  `UserSettings()` instance. Regression test verified failing before the fix.
- **Holiday presets localized.** `name`/`detail` route through `L()`; `count`
  changed from the baked string "13 天 / 年" to a `HolidaySourceCount` enum
  rendered per-language by `HolidaySourceCountFormatter`. Lunar strings stay
  Chinese by design.
- **Toggle/segmented interaction polish.** `PillToggle`'s track was a
  `CAGradientLayer` painting a solid fill — now a plain `CALayer`. Both controls
  ease-out over 0.16s on change, gated to real interaction: `apply(animated:)`
  is `false` from `init`/`layout()`/`viewDidChangeEffectiveAppearance()`, so
  there is no animation on first paint or on a light/dark switch.

Design conformance and defects (all found by visual QA, not by tests):

- **The dark popover read navy and did not match the design.** `glassScrim`
  tinted everything with `0x0E1428` at 62% over an `NSVisualEffectView`. The
  design system has no navy, no glass and no blur — it specifies the popover as
  flat opaque `--surface` with a `--line` hairline and `--glass-shine: none`.
  The glass tokens came from a sibling design system; they are gone. This
  reverts the material added in 55a70a3.
- **The year/decade/century picker was never migrated to v2** and was broken:
  stock Aqua `NSButton` bezels, decade titles truncating to "2020…" (a
  two-line `"2020\n2029"` the button could not render), and huge row gaps (a
  fixed height of 86 that `.rounded` bezels refuse to grow into). Rebuilt on
  the design tokens; out-of-range items are now de-emphasized.
- **The calendar header title drifted left/right between renders.** The row is
  `[left, spacer, title, spacer, right]` with two equal-priority spacers and
  nothing tying them together, so the engine could give all the slack to
  either. Spacers are now pinned to equal widths, matching the design's
  space-between with equal tile groups.

**宜/忌 (recommended actions) removed from the product** — client, shared
packages and chrome extension. See Resolved Decisions in the architecture doc.

Test status: 26 passing (was 30; the recommended-action suite and store
assertion went with the feature). Verified visually in the running app.

Known follow-ups:
- Weekday headers are intentionally English mono (`MON`) per the design; the
  lunar/`保存` strings follow the language setting. Not a bug.
- The `AppDelegate.swift:42` Swift 6 `SendableClosureCaptures` warning predates
  this work and is unaddressed.

## Status as of 2026-07-02 (cont.) — Holiday Hosting, Feedback Toasts, Glass Material

Three follow-up commits on top of the v2 redesign below:

- **CN holiday iCal hosting** (`apps/holidays-ical`): a Cloudflare Pages
  Function project serving `/cn.ics` (and other regions lacking an official
  feed) from the maintained holiday-cn dataset (off-days only, surrounding 3
  years, cached ~24h). Mac client holiday subscription sources: CN → this
  hosted feed (`daylight-holidays.pages.dev/cn.ics`, needs
  `wrangler pages deploy` before it resolves — deploy status not yet
  verified), HK → GovHK official ical (1823.gov.hk) directly, TH →
  officeholidays.com/ics/thailand directly (new region), TW → custom-only.
- **Holiday tint + action feedback toasts**: public holidays get a quiet
  muted-red tint (`Palette.holiday`, `CalendarDayTitle.isHoliday`) on the day
  number and label. A reusable toast on the popover root (survives screen
  re-renders) now confirms user actions: save/quick diary, add/remove mark,
  subscribe holidays (count or failure), export diary.
- **Frosted-glass popover material**: popover base is now an
  `NSVisualEffectView` (`.popover`, behind-window) with an appearance-aware
  scrim (`Palette.glassScrim`) so ink text stays legible; cards use a
  translucent glass fill/stroke (`Palette.glassFill`/`glassStroke`) instead of
  a solid surface. Accent colors stay monochrome ink — no aurora gradient,
  unlike the sibling Meet design system's glass surfaces.

Updated known follow-up: `Components.swift` (311 lines) now also exceeds the
300-line guideline, alongside `CalendarSettingsPanel.swift` (313) and
`DateDetailPanel.swift` (376); split still pending.

Test status: 28 tests passing (`swift test`, verified 2026-07-16).

## Status as of 2026-07-02 (Redesign v2)

Reworked the popover UI to the `昼间 Redesign.dc.html` "朴素/plain" design
(near-monochrome, hairline, matte). Key changes:

- `DesignSystem.swift` — appearance-aware color/font/metric tokens from the
  design system CSS (`--ink/--surface/--line/--accent/--pos/--neg`).
- `Components.swift` — shared kit: `PillToggle`, icon tiles, cards, hairlines,
  filled ink button.
- Flat moon disc (`Moon/MoonDiscView.swift`, `MoonArt`) replaces the SceneKit
  sphere — hairline circle + inked terminator arc, also drives the status icon.
- Calendar cells/grid restyled: mono day number + lunar sub, solar-term
  emphasis, mark dot, today/selected/weekend/outside states, week column.
- Three-screen popover routing (calendar / settings / status editor / detail),
  sized to content via `preferredContentSize` (no fixed height).
- Configurable menu bar: ordered, reorderable status segments
  (`statusSegments`) rendered as one template image (`Status/StatusBarRenderer`),
  edited in `Panels/StatusBarEditorPanel` (add/remove/up-down + live preview).

Settings (redesign v2, fuller): grouped 显示 / 日历 / 工具栏 / 数据与同步 / 关于
with a `v2.0` header badge and footer note. Uses a new `SegmentedControl`
(外观 跟随/浅/深, 每周起始日 周一/周日), select/nav/action rows, and 导出日记
(real NSSavePanel export). iCloud 同步 and 每日提醒 rows are omitted (no backend).

Moon feature split by the design's privacy model:
- Simple flat moon everywhere (calendar row, detail card) — phase/illumination/
  age from date only, no location. Both are tappable (chevron) to open 3D.
- A dedicated `Moon/Moon3DPanel` (SceneKit) loading the bundled NASA LRO USDZ
  model (normalized to unit radius), reachable by tapping the moon row/card.
  Location is requested ONLY here; usage string (install-local.sh Info.plist)
  explains it is for the 3D model. `LocationService` no longer auto-prompts
  (gated on explicit `start()`), so other screens never prompt.
- `openMoon` shows a custom pre-prompt (`Panels/LocationPromptPanel`) explaining
  why, with 允许使用定位 / 暂不开启, before the system dialog — only when the OS
  status is `.notDetermined`. 暂不开启 opens 3D with the equator fallback.

Holiday subscription (`Holidays/`): a 数据与同步 → 订阅节假日 screen picks a source
(中国大陆/香港/台湾/自定义 iCal), pastes an iCal URL, sets 每天/每周 auto-update,
and 订阅并标注 does a real iCal fetch+parse (`HolidayService`) into public days.
Popover width widened to 412 for the denser settings/holiday rows.

Solar-term bug FIXED: `LunarCalendar.solarTermDay` now uses the 公式法 (紫金山)
per-term constants for 2000–2099 (exact, China time), with the corrected linear
formula (base 小寒 1900-01-06 02:05 UTC, read in UTC+8) as fallback for other
years. Regression test `LunarCalendarTests` locks known 2025/2026 dates and that
2026-07-02 is 十八 (not 小暑). Was ~5 days early before.

Typography: bundled IBM Plex Sans (variable, weighted via the `wght` axis) and
IBM Plex Mono (Regular/Medium) in Resources, registered at first use
(`Fonts.ensureRegistered`), replacing the system-font mapping. Mono labels now
carry letter-spacing (`UI.label(tracking:)`) to match the design's tracked look.

Localization (`Localization.swift`): EN / ZH / Thai, keyed by the Chinese source
string (zh needs no table). `L("…")` shorthand; `Loc.language` set from settings
at the start of each render pass and before the status-bar refresh. A 语言 /
Language segmented control sits at the top of the 显示 group; weekday names and
month/day formatting are language-aware. Lunar text stays Chinese (农历 feature).

`PopoverViewController` split into `+CalendarScreen` and `+Navigation` extensions
(196/149/107 lines). Solar-term regression + status/lunar tests: 23 passing.

Parity pass (reference apps/chrome-extension + packages/{sync,domain,core-calendar}):
- `PublicCalendarDay` gained `description`/`sourceUrl` and a custom decoder so a
  feed omitting `isImportant` no longer drops the whole array; sync filters to
  valid types (holiday/workday/observance).
- Recommended actions now model the full `{good,bad}` rules (base/weekend/date +
  per-item url) instead of flattened strings; `RecommendedActionPicker` mirrors
  the TS `pickRecommendedActions` (uint32 31-hash stable index + weekend swap),
  used by the detail panel (one 宜/one 忌 per date).
- Periodic remote sync added (12h timer, matching the chrome worker) alongside
  the launch sync.
- iCal holiday subscription writes a separate `holidayDays` store, merged with
  remote `publicDays` in `publicDay(for:)`, so the two paths stop clobbering.
- Diary wire format aligned to the TS shape: key `diaryEntries`, `updatedAt`
  as an ISO-8601 string.
- Intentional divergences kept: mac uses `statusSegments` (status-bar editor)
  instead of TS `actionIconMode`; `showDailyDetail` ≈ `autoOpenTodayDetail`.

Known follow-ups:
- `read()` falls back to defaults if any settings key is missing (adding a field
  resets a user's stored settings); consider per-field decodeIfPresent.
- `Panels/CalendarSettingsPanel.swift` (309) and `Panels/DateDetailPanel.swift`
  (371) still exceed the 300-line guideline; split pending.
- Holiday preset day-counts ("13 天 / 年") and lunar strings are not localized.

## Status as of 2026-06-29

The macOS client is implemented as a Swift Package in `apps/mac-menubar`.
It builds a local `DaylightMenuBar.app` with `scripts/install-local.sh`.

Current local app path:

```text
apps/mac-menubar/.build/local/DaylightMenuBar.app
```

## Implemented

- Menu bar status item with date, weekday emoji, and moon phase title modes.
- Native popover shell using AppKit.
- Month, year, decade, and century calendar navigation.
- Keyboard shortcuts for date movement and view switching.
- Week number display with ISO 8601, US, Arabic, and Hebrew week rules.
- Lunar date and solar term display in day cells.
- Public calendar day names, marks, diary entries, recommended actions, and display settings.
- Local `UserDefaults` persistence for settings, marks, diary, public days, and recommendations.
- Remote sync for public calendar and recommended action payloads.
- Location-based moon observation data using CoreLocation.
- NASA LRO Moon model resource is bundled, but the current compact moon panel uses a fallback sphere because the USDZ model is not yet visually suitable in the small popover.
- SwiftPM test target `DaylightMenuBarKitTests` covers calendar grid, week rules, day title formatting, settings defaults, mark matching, status title modes, and moon observation ranges.

## Known Problems

- The current popover UI is functional but not approved as production design.
- Recent wide two-column and oversized inspector attempts were rejected after visual review.
- The active direction is to pause UI polish until a formal design is available.
- The next UI iteration should start from a compact menu bar popover, not a large application window.
- AppKit layout needs visual QA after every layout change, not just Swift tests.

## Resume Checklist

1. Start from the current compact single-column popover implementation.
2. Do not expand the popover into a large inspector-style window without a design.
3. Keep day cells readable: no truncated date text and no unstable row heights.
4. Keep every source file under 300 lines and every module directory under 10 files.
5. Run `swift test` and `swift build` after changes.
6. Rebuild locally with `scripts/install-local.sh` and relaunch the app before visual review.

## Last Verified Commands

```bash
cd apps/mac-menubar
swift test
swift build
scripts/install-local.sh
```

Test status at handoff: 20 tests passing.
