# Chrome Extension Rewrite — Completeness Audit

Audit date: 2026-08-18. Baseline: `docs/rewrite-architecture.md`. New code: `apps/chrome-extension/` + `packages/*`. Legacy reference: `src/` (MV2, not audited as target). `npm run rewrite:typecheck` and `npm run rewrite:test` both pass at audit time.

---

## 1. Summary

The rewrite is a **functional MV3 month-view calendar** with shared packages for domain types, lunar/solar-term/moon calculations, Chrome storage repositories, and typed remote sync. Core month-grid behaviour, lunar display, three mark types, diary persistence, holiday subscriptions (multi-source iCal with per-source colours), browser-action icon modes, and a v2 plain-design popup are in place.

It is **not feature-complete** against the legacy MV2 inventory. Large gaps: year/decade/century views, keyboard shortcuts and shortcut help, About/FAQ/changelog panels, dark-mode and auto-open-today settings UI, mark editing, extension self-reload, and any E2E test suite. Two inventory items are **intentionally dropped**: recommended actions (宜/忌) and Vitamin promotional content (`docs/rewrite-architecture.md` Resolved Decisions).

Architecturally, shared TypeScript packages are sound (strict TS, no `chrome.*` in `packages/*`, file sizes under 300 lines), but UI render modules call astronomy helpers directly, two public factory functions exceed the 50-line function cap, and the “E2E first” goal has zero E2E coverage. Lunar/solar-term/moon logic is duplicated in Swift with documented parity tooling; iCal holiday parsing is duplicated without cross-language contract tests.

---

## 2. Feature parity — Current Product Inventory

| Item | Status | Evidence | What's missing |
|------|--------|----------|----------------|
| Month view | **Implemented** | `apps/chrome-extension/src/popup-render.ts:61-83` (`renderMonth`, `buildMonthGrid`) | — |
| Year view | **Missing** | Legacy: `src/popup/App.tsx:88` (`view` state includes `"year"`). New popup has no year view or zoom-out navigation. | Entire year picker/grid flow |
| Decade view | **Missing** | Legacy: `src/popup/App.tsx:88` (`"decade"`). Mac: `PopoverViewController+Navigation.swift:42-45` (`zoomOut` to decade). Chrome: not verified in `apps/chrome-extension/src/*` | Entire decade picker/grid flow |
| Century view | **Missing** | Legacy: `src/popup/App.tsx:88` (`"century"`). Mac: `PopoverViewController+Navigation.swift:42` (`.century`). Chrome: not found | Entire century picker/grid flow |
| Single-month display | **Implemented** | `packages/domain/src/settings.ts:34` (`showDoubleCalendar: false` default); `popup-render.ts:51-55` (second month only when `showDoubleCalendar`) | — |
| Double-month display | **Implemented** | `popup-render.ts:52-55`; setting toggle `popup-render.ts:105` | — |
| Week numbers (optional) | **Implemented** | `popup-render.ts:72-73,125-126,145-147`; setting `popup-render.ts:104` | — |
| Calendar week rules: ISO 8601 | **Implemented** | `packages/core-calendar/src/constants.ts:63-68`; `getWeekNumber` `date-key.ts:57-67`; tests `core-calendar.test.ts:101-104` | — |
| Calendar week rules: US | **Implemented** | `constants.ts:65`; tests `core-calendar.test.ts:105,107` | — |
| Calendar week rules: Arabic | **Implemented** | `constants.ts:66`; tests `core-calendar.test.ts:106` | — |
| Calendar week rules: Hebrew | **Implemented** | `constants.ts:67`; `parseSettings` accepts `"hebrew"` `chrome-repositories.ts:177-179`; week math uses `FIRST_WEEKDAY_BY_CALENDAR` | — |
| Date selection → detail | **Implemented** (inline panel) | `popup-render.ts:56` (`renderDetail`); `popup.ts:40` (`onSelectDate`). Detail is always visible below grid, not a modal dialog. | Legacy used a flip-card/dialog pattern (`src/popup/App.tsx:6-7`); behaviour differs but detail content updates on selection |
| Keyboard shortcuts (navigation, settings, detail, help) | **Missing** | Legacy: `src/popup/App.tsx:7,18-78` (`GlobalHotKeys`, `keyMap`). New: no `keydown` handlers or `commands` in `public/manifest.json` | All listed shortcuts (arrows, `d`, `s`/`c`, `h`/`shift+?`, `m`/`o`, `w`, `f`) |
| Gregorian → lunar conversion | **Implemented** | `packages/core-calendar/src/lunar.ts`; used in grid `calendar-grid.ts:52-53` and detail `detail-render.ts:153-159` | — |
| Heavenly stem / earthly branch year | **Implemented** | `lunar.ts:36,120-122` (`yearName`); displayed `popup-render.ts:258`, `detail-render.ts:158` | — |
| Solar term calculation | **Implemented** | `packages/core-calendar/src/solar-terms.ts`, `solar-term-table.ts`; tests `core-calendar.test.ts:26-38` | — |
| Moon phase (icon rendering) | **Implemented** | `packages/core-calendar/src/moon-phase.ts`; action icon `icon-renderer.ts:23-25,61-74`; detail card `detail-cards.ts` | — |
| Lunar + solar term in tiles | **Implemented** | `popup-render.ts:134-139` (solar term or `dayName` in `.lunar` span) | — |
| Lunar + solar term in date detail | **Implemented** | `detail-render.ts:148-160` (header); solar term card `detail-render.ts:35-48` | — |
| Public holiday / workday data (local after sync) | **Implemented** | Holiday iCal: `holiday-subscriptions.ts:19-50`; remote JSON: `service-worker.ts:45-62` (`syncPublicCalendar`); storage `chrome-repositories.ts:70-77,132-136` | — |
| Remote default config | **Retired** | The old config host and its scheduled fetch were removed. Holiday subscriptions use their configured iCal sources directly. | — |
| Remote URLs from default config | **Retired** | The extension no longer reads remote source URLs from a default config. | — |
| PouchDB replication | **Intentionally replaced** | Architecture Non-Goals: no PouchDB by default. New path uses typed JSON + iCal (`packages/sync`) | Not a gap |
| Yearly marks | **Implemented** | `popup-model.ts:85-86`; UI `detail-render.ts:100-112,170-171` | — |
| Monthly marks | **Implemented** | `popup-model.ts:87-88`; UI `detail-render.ts:172` | — |
| One-time marks | **Implemented** | `popup-model.ts:89`; UI `detail-render.ts:170` | — |
| Mark edit (change content) | **Partial** | Create: `popup-model.ts:82-90`; delete: `detail-render.ts:118` (click chip). Legacy inline edit: `src/popup/components/DateMark.tsx:16-43` | No edit-in-place; user must delete and re-add |
| Diary entries | **Implemented** | `detail-render.ts:125-135`; persist `popup-model.ts:97-100`; repo `chrome-repositories.ts:53-68` | — |
| Local-only user data | **Implemented** | `chrome.storage.local` for marks/diary `chrome-repositories.ts:43,60`; sync storage for settings `chrome-repositories.ts:28` | — |
| Dark mode setting | **Partial** | CSS: `styles.css:23-41` (`.dark`, `prefers-color-scheme`). `applyColorScheme` `popup-render.ts:239-241`. Setting parsed `chrome-repositories.ts:157`. Legacy toggle: `src/popup/components/Settings.tsx:55` | **No settings UI** to choose light/dark/system (settings panel `popup-render.ts:98-109` omits `colorScheme`) |
| Lunar date display setting | **Implemented** | `popup-render.ts:103` | — |
| Daily auto-open today's detail | **Partial** | Field exists `packages/domain/src/settings.ts:18,31`; parsed `chrome-repositories.ts:159`. Legacy behaviour: `src/popup/components/Calendar.tsx:167` | **Never read in popup bootstrap** (`popup.ts` has no `autoOpenTodayDetail` logic) |
| Emoji browser-action icon | **Implemented** | `icon-renderer.ts:19-21,54-58`; setting `popup-render.ts:107,194-195` | — |
| Moon phase browser-action icon | **Implemented** | `icon-renderer.ts:23-25,61-74` (evening hours `76-78`); setting option `popup-render.ts:195` | — |
| Week numbers setting | **Implemented** | `popup-render.ts:104` | — |
| Recommended actions (宜/忌) | **Intentionally dropped** | `docs/rewrite-architecture.md:406-410` | — |
| Double calendar setting | **Implemented** | `popup-render.ts:105` | — |
| Calendar type setting | **Implemented** | `popup-render.ts:106,191-192` | — |
| Browser action: today's date icon | **Implemented** | `icon-renderer.ts:27-28,43-52` (default `actionIconMode: "date"`) | — |
| Browser action title (Gregorian, weekday, lunar, solar term) | **Implemented** | `icon-renderer.ts:31-40` | — |
| Icon refresh alarm (10 min) | **Implemented** | `service-worker.ts:18,33-34` (`periodInMinutes: 10`) | — |
| Extension self-reload (600 min) | **Missing** | Legacy: `src/background.ts:216-223` (`periodInMinutes: 600`, `chrome.runtime.reload()`). New service worker: no reload alarm (`service-worker.ts:17-19` only icon + sync alarms) | 600-minute reload behaviour |
| About panel | **Missing** | Legacy: `src/popup/components/About.tsx:81-156`. New: not found in `apps/chrome-extension/src/*` | About content |
| FAQ | **Missing** | Legacy: `About.tsx:102-122` | FAQ content |
| Changelog | **Missing** | Legacy: `About.tsx:134-137` | Changelog content |
| Keyboard shortcut reference | **Missing** | Legacy: `src/popup/components/HotKeyMap` (imported `App.tsx:14`); `keyMap` `App.tsx:18-78` | Shortcut help screen |
| Promotional / Vitamin API content | **Intentionally dropped** | Architecture Non-Goals / Resolved Decisions; legacy `src/popup/components/Vitamin` (import `App.tsx:16`) absent from rewrite | — |

---

## 3. Rewrite goal violations

Severity-ordered. Line counts from source at audit time.

### 3.1 No E2E tests (goal: “Add E2E tests before rebuilding user flows”)

- **Violation:** No `tests/e2e/` directory; no Playwright or extension E2E harness found in repo.
- **Evidence:** `package.json:31` (`rewrite:test` runs 7 unit/smoke files only). Proposed `tests/e2e/` in `docs/rewrite-architecture.md:109-110` does not exist.
- **Existing tests (7 files):**
  - `packages/core-calendar/tests/core-calendar.test.ts` — lunar, solar terms, moon phase, grid, marks matching (pure logic).
  - `packages/storage/tests/storage.test.ts` — in-memory repositories smoke test.
  - `packages/sync/tests/sync.test.ts` — config parse, public-calendar sync, iCal parser edge cases.
  - `apps/chrome-extension/tests/locale.test.ts` — `t()`, `parseSettings`, Thai BE year.
  - `apps/chrome-extension/tests/solar-term-icons.test.ts` — SVG glyph distinctness (not read in full; file exists).
  - `apps/chrome-extension/tests/detail-cards.test.ts` — solar-term card, moon SVG.
  - `apps/chrome-extension/tests/holiday-storage.test.ts` — mocked Chrome storage, overlapping subscription hits.
- **Untested major flows:** popup open/render, date selection UI, mark/diary persistence across restart (real Chrome storage), settings → icon refresh, service-worker alarms, scheduled sync end-to-end, holiday permission workflow.

### 3.2 Public functions over 50 lines

| Function | File | Lines | Length |
|----------|------|-------|--------|
| `createChromeRepositories` | `apps/chrome-extension/src/chrome-repositories.ts` | 20–113 | **94** |
| `createMemoryRepositories` | `packages/storage/src/memory-repositories.ts` | 20–101 | **82** |

No other functions over 50 lines detected in `apps/chrome-extension/src` or `packages/*/src` (script: brace-matched `function` declarations).

### 3.3 Thin UI clients — astronomy / sync in render modules

Goal: no direct persistence, sync, or astronomy logic in components (`docs/rewrite-architecture.md:82`).

| Module | Violation | Evidence |
|--------|-----------|----------|
| `popup-render.ts` | Astronomy in UI layer | Imports `buildMonthGrid`, `getLunarDate`, `getSolarTermLabelZh`, `getWeekNumber` from `@daylight/core-calendar` (`popup-render.ts:1`) |
| `detail-render.ts` | Astronomy in UI layer | Imports `getLunarDate`, `getWeekNumber` (`detail-render.ts:1`); cards call `getSolarTermCardData` / `getMoonCardData` (`detail-render.ts:35-55`) |
| `detail-cards.ts` | Astronomy wrapper in app | Imports `getMoonPhase`, `getSolarTerm` (`detail-cards.ts:1`) |
| `icon-renderer.ts` | Astronomy in shell UI | Imports `getLunarDate`, `getMoonPhase` (`icon-renderer.ts:7`) |
| `holiday-render.ts` | Sync constants in UI | Imports `HOLIDAY_SOURCES` from `@daylight/sync` (`holiday-render.ts:7`) |

`popup-model.ts` correctly uses repositories (`popup-model.ts:30-46`) and is the appropriate orchestration layer. `popup.ts` wires handlers only (`popup.ts:28-66`).

### 3.4 Branded / discriminated types — partial adherence

**Present:**
- `LocalDateKey`, `YearMonthKey` branded in `packages/domain/src/date.ts:7-8`.
- `DateMark` discriminated union `packages/domain/src/user-data.ts:11-27`.
- `SyncStatus` union `packages/domain/src/sync.ts:9`.

**Weak spots:**
- Storage validation accepts plain strings for dates: `isDateMark` checks `typeof value.date === "string"` (`chrome-repositories.ts:209`), not branded keys.
- Widespread `as LocalDateKey` casts in tests and some app code (e.g. `detail-cards.test.ts:11`) bypass compile-time branding at boundaries.
- `SyncState` defined but **never persisted or used** outside `packages/domain/src/sync.ts` (repo-wide grep).

### 3.5 Goals that pass

| Goal | Status | Evidence |
|------|--------|----------|
| Manifest V3 | **Pass** | `apps/chrome-extension/public/manifest.json:2` (`"manifest_version": 3`), service worker `manifest.json:12-14` |
| Strict TypeScript | **Pass** | `"strict": true` in all rewrite tsconfigs (e.g. `apps/chrome-extension/tsconfig.json:7`, `packages/domain/tsconfig.json:8`, `packages/core-calendar/tsconfig.json:7`, `packages/storage/tsconfig.json:7`, `packages/sync/tsconfig.json:7`) |
| No file over 300 lines | **Pass** | Largest: `popup-render.ts` 277 lines, `chrome-repositories.ts` 222, `solar-term-icons.ts` 232 (wc audit) |
| No Chrome APIs in `packages/*` | **Pass** | `rg 'chrome\.|browser\.' packages/` — no matches |
| `rewrite:typecheck` / `rewrite:test` | **Pass** | Verified 2026-08-18 |

### 3.6 Other architectural notes (not inventory gaps)

- Proposed `packages/ui` does not exist; Chrome keeps renderers in `apps/chrome-extension/src/` (acceptable deviation if intentional).
- PouchDB replication correctly abandoned per Non-Goals.

---

## 4. Shared logic — TypeScript vs Swift

### 4.1 Rules duplicated in both languages

| Rule | TypeScript | Swift |
|------|------------|-------|
| Lunar calendar (1949–2100 table) | `packages/core-calendar/src/lunar.ts`, `constants.ts:17-37` | `apps/mac-menubar/Sources/DaylightMenuBar/LunarCalendar.swift` |
| Solar term day table | `packages/core-calendar/src/solar-term-table.ts` | `LunarCalendar.swift:51-54` (`termTable`) |
| Moon phase buckets | `packages/core-calendar/src/moon-phase.ts` | `apps/mac-menubar/Sources/DaylightMenuBar/MoonPhase.swift` (per `docs/calendar-accuracy.md:52-55`) |
| iCal holiday parsing | `packages/sync/src/holiday-ical.ts` | `apps/mac-menubar/Sources/DaylightMenuBar/Holidays/HolidayService.swift` |
| Solar term icons (geometry) | `apps/chrome-extension/src/solar-term-icons.ts` | `apps/mac-menubar/Sources/DaylightMenuBar/Calendar/SolarTermIconGlyphs.swift` (per architecture doc) |
| Week / month grid | `packages/core-calendar/src/calendar-grid.ts` | Mac `CalendarModel` / month views (Swift; not line-audited here) |

Chrome consumes TS packages; Mac reimplements in Swift — expected for AppKit.

### 4.2 Parity mechanisms

- **`docs/calendar-accuracy.md`** documents full-range (55,489-day) TS vs Swift dumps, byte-identical after 2026-07 fixes; solar-term table generator `packages/core-calendar/tools/generate-solar-term-table.ts`.
- **Golden tests:** `packages/core-calendar/tests/core-calendar.test.ts`; `apps/mac-menubar/Tests/DaylightMenuBarKitTests/LunarCalendarTests.swift` (cited in calendar-accuracy doc).
- **Holiday iCal:** Swift has `HolidayServiceTests.swift`; TS has `packages/sync/tests/sync.test.ts` iCal cases — **no automated cross-language fixture comparison** found.

### 4.3 Silent divergence risks

- **Lunar table / solar term table:** manual sync required; comments in both files warn they must stay identical (`LunarCalendar.swift:8-9`, `calendar-accuracy.md:81-84`).
- **iCal parser:** independent implementations; only per-language tests.
- **Solar term SVG vs NSBezierPath:** duplicated art paths; no shared coordinate data file.
- **Settings schema:** architecture doc notes macOS needs custom decoder for new fields (`rewrite-architecture.md:475-477`); Chrome `parseSettings` is more forgiving (`chrome-repositories.ts:152-166`).

---

## 5. Gaps vs macOS client (platform-neutral features)

| Feature | macOS | Chrome extension | Evidence |
|---------|-------|------------------|----------|
| Multi-language UI (zh / en / th) | Yes | **Yes** | Chrome: `locale.ts:64+` translation table; setting `popup-render.ts:102,188-189`. Mac: `Localization.swift` |
| Multi-source iCal holidays + per-source colours | Yes | **Yes** | Chrome: `holiday-render.ts`, `popup-model.ts:106-122`, `holiday-subscriptions.ts`. Domain: `packages/domain/src/holidays.ts` |
| Diary export (JSON) | Yes | **Missing** | Mac: `CalendarSettingsPanel.swift:209-227` (`exportDiary`). Chrome: `deleteDiaryEntry` exists (`chrome-repositories.ts:64-67`) but no export UI or API |
| Customisable toolbar / status icon | Yes (segment editor) | **Partial** | Mac: `StatusBarEditorPanel.swift`, `statusSegments` in `Storage.swift:36`. Chrome: single `actionIconMode` select (`popup-render.ts:107,194-195`) — date / emoji / moon only; no multi-segment status bar equivalent (expected platform difference for browser action, but less configurable than Mac) |
| Year / decade / century zoom | Yes (Mac) | **Missing** | Mac: `PopoverViewController+Navigation.swift:41-45`. Chrome: month only |
| Dark mode setting UI | Yes | **Missing** | Mac: `CalendarSettingsPanel.swift:51` appearance segmented control. Chrome: no `colorScheme` in settings panel |
| System calendar integration | Yes | N/A (macOS-only) | Mac EventKit — exclude |
| 3D moon / Core Location | Yes | N/A | Architecture: Chrome flat SVG only (`rewrite-architecture.md:453-454`) |

---

## 6. Prioritised next steps (user-visible impact)

| Priority | Work | Rough size |
|----------|------|------------|
| 1 | **Keyboard shortcuts** — port legacy `keyMap` (`src/popup/App.tsx:18-78`) to popup + manifest `commands` if needed | M (2–3 days) |
| 2 | **Settings UI gaps** — dark/light/system (`colorScheme`) and wire `autoOpenTodayDetail` in `popup.ts` | S (1 day) |
| 3 | **Secondary content** — About, FAQ, changelog, shortcut reference (can reuse legacy copy from `About.tsx`) | M (2 days) |
| 4 | **Year/decade/century views** — unless product formally drops them per Mac redesign note | L (5–8 days) |
| 5 | **Playwright extension E2E** — minimal slice from architecture doc: open popup, select day, mark, diary, settings → icon | L (3–5 days setup + flows) |
| 6 | **Mark editing** — inline edit like legacy `DateMark.tsx` | S (1 day) |
| 7 | **Diary export** — parity with Mac JSON export | S (1 day) |
| 8 | **Refactor thin UI** — move astronomy calls from `popup-render.ts` / `detail-render.ts` into `popup-model` or a view-model layer | M (2–3 days) |
| 9 | **Split `createChromeRepositories`** to satisfy 50-line public function rule | S (half day) |
| 10 | **Extension reload alarm** — only if still needed on MV3 (`src/background.ts:222-223`) | S (half day) |
| 11 | **Cross-language iCal fixture tests** — shared golden `.ics` files for TS + Swift parsers | M (1–2 days) |

---

## Appendix: intentionally dropped inventory items

- **Recommended actions (宜/忌):** removed per `docs/rewrite-architecture.md:406-410`. Legacy remains in `src/popup/components/recommendAction.tsx`.
- **Vitamin / promotional API:** removed per Non-Goals (`rewrite-architecture.md:95`). Legacy `src/popup/components/Vitamin` (import `App.tsx:16`).

---

## 7. Release-state finding (added after the code audit)

The audit above compares code against the rewrite spec. It does not describe
what is actually published, which turns out to dominate the priority order.

| | Published (Chrome Web Store / Edge) | Rewrite in this repo |
|---|---|---|
| Source | `src/` + `public/manifest.json`, built by root `yarn build` (`webpack/webpack.common.js:138`) | `apps/chrome-extension/` |
| Manifest | **V2** (`public/manifest.json:manifest_version = 2`) | V3 (`apps/chrome-extension/public/manifest.json:manifest_version = 3`) |
| Version | `0.2.1` | `0.0.0` |
| Name | 昼间日历 | Daylight Calendar |

Verified externally on 2026-08-18:

- MV2 extensions stopped running in Chrome stable on **2025-07-24** (Chrome 138),
  with no user or enterprise re-enable path remaining.
- The Chrome Web Store removes all remaining MV2 listings on **2026-08-31**.

So the shipped extension has been non-functional for Chrome users for over a
year, and its store listing is 13 days from deletion at the time of writing.
Shipping an MV3 update preserves the existing listing, its URL, reviews and
install base; letting the purge run does not.

This outranks every item in section 6. Blockers to shipping the rewrite as an
update to the existing listing:

1. `version` is `0.0.0` and must exceed the published `0.2.1`.
2. `name` differs from the published listing (昼间日历 → Daylight Calendar);
   changing it is a product decision, not an accident to ship by default.
3. Feature regressions against the published build — keyboard shortcuts,
   year/decade/century views, About/FAQ/changelog — would reach existing users
   as losses (section 2).
4. No E2E coverage of the flows an update would put in front of real users
   (section 3.1).

**Not verified:** the Microsoft Edge Add-ons store runs its own MV2 timeline;
the 2026-08-31 date above is Chrome's and must not be assumed to apply to Edge.
Check before relying on it.

The product site published at `apps/site/` links to both store listings, so the
Chrome link becomes dead if the purge removes the listing.

---

## 8. Status update (2026-08-19)

Work landed since the audit, so section 6's ordering is stale:

- **Done:** keyboard shortcuts and the shortcut reference; About; the calendar-type
  dropdown; per-screen routing inside the popup (detail and settings are full
  screens, not tabs and not stacked panels); the toolbar icon's calendar
  silhouette, theme adaptation and legible size; holiday names in the grid, which
  were missing because the extension resolved a day from `publicDays` alone while
  the Mac resolves subscription hits first; the moon summary row; the quick diary,
  now a timeline of thoughts sharing the macOS model.
- **Still open:** year/decade/century views, mark editing, diary export, the
  dark-mode setting, and E2E coverage — still zero, against a stated goal of
  writing it before rebuilding user flows.
- **Unchanged and now urgent:** the published extension is still the MV2 build.
  See §7.
