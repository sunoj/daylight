# Daylight Rewrite Architecture

## Purpose

Daylight will be rewritten as a shared calendar product with two clients:

- A Chrome extension.
- A macOS menu bar client.

The rewrite should preserve the useful product behavior from the current extension while replacing the old implementation structure. The new codebase must keep domain logic independent from browser and macOS APIs so both clients can share the same calendar, lunar, holiday, mark, diary, and settings behavior.

## Current Product Inventory

The existing project is a Manifest V2 Chrome extension with a React popup, a background page, PouchDB-backed local data, and local calendar calculations.

### Calendar

- Month, year, decade, and century views.
- Single-month and double-month display.
- Optional week numbers.
- Configurable calendar week rules: ISO 8601, US, Arabic, and Hebrew.
- Date selection opens a detail dialog.
- Keyboard shortcuts for date navigation, settings, detail view, and help.

### Local Calendar Calculations

- Gregorian to Chinese lunar date conversion.
- Heavenly stem and earthly branch year labels.
- Solar term calculation.
- Moon phase calculation for icon rendering.
- Lunar date and solar term display in calendar tiles and date details.

### Public Calendar Data

- Public holiday and adjusted workday data is stored locally after a remote sync.
- The legacy background page used to load remote default configuration and replicate PouchDB databases. That remote configuration flow has been retired.

### User Data

- Date marks:
  - Yearly marks.
  - Monthly marks.
  - One-time marks.
- Date diary entries.
- Data is local-only in the current app.

### Settings

- Dark mode.
- Lunar date display.
- Daily auto-open of today's detail.
- Emoji browser action icon.
- Moon phase browser action icon.
- Week numbers.
- Recommended actions. Intentionally dropped from the rewrite — see Resolved
  Decisions.
- Double calendar view.
- Calendar type.

### Shell Behavior

- Browser action icon shows today's date, weekday emoji, or moon phase.
- Browser action title includes Gregorian date, weekday, lunar date, and solar term.
- Icon refresh runs on an alarm every 10 minutes.
- The extension reloads itself every 600 minutes.

### Secondary Content

- About panel.
- FAQ.
- Changelog.
- Keyboard shortcut reference.
- Promotional content from the Vitamin API.

## Rewrite Goals

- Use Manifest V3 for the Chrome extension.
- Build a native-feeling macOS menu bar client.
- Share all business rules between clients.
- Keep UI clients thin: no direct persistence, sync, or astronomy logic in components.
- Use strict TypeScript in shared and web code.
- Keep source files under 300 lines and public functions under 50 lines.
- Use explicit domain types instead of unstructured objects.
- Add E2E tests before rebuilding user flows.
- Avoid legacy fallback paths unless a migration task explicitly requires them.

## Non-Goals

- Do not preserve the current PouchDB replication design by default.
- Do not keep Manifest V2 compatibility.
- Do not keep current React 16, TypeScript 3.7, or Webpack architecture.
- Do not place Chrome or macOS APIs inside shared domain modules.
- Do not rebuild the promotional system unless it is intentionally kept as a product feature.

## Proposed Repository Structure

```text
apps/
  chrome-extension/
  mac-menubar/
packages/
  core-calendar/
  domain/
  storage/
  sync/
  ui/
tests/
  e2e/
  integration/
  unit/
docs/
  rewrite-architecture.md
```

## Shared Packages

### `packages/domain`

Defines shared product types and module contracts.

Suggested exports:

- `CalendarDate`
- `DateId`
- `LunarDate`
- `SolarTerm`
- `MoonPhase`
- `PublicCalendarDay`
- `DateMark`
- `DiaryEntry`
- `UserSettings`
- `SyncState`
- `Result`

Rules:

- Use branded types for IDs and date keys.
- Use discriminated unions for mark types and sync status.
- Keep this package dependency-free when practical.

### `packages/core-calendar`

Owns pure calendar logic.

Suggested modules:

- `gregorian`
- `lunar`
- `solar-terms`
- `moon-phase`
- `calendar-grid`
- `date-format`
- `public-day-matcher`

Rules:

- No UI imports.
- No browser APIs.
- No filesystem APIs.
- Deterministic functions where possible.
- Timezone must be explicit at the public API boundary.

### `packages/storage`

Provides persistence interfaces and adapters.

Suggested modules:

- `settings-repository`
- `marks-repository`
- `diary-repository`
- `public-calendar-repository`
- `chrome-storage-adapter`
- `indexeddb-adapter`
- `sqlite-adapter`

Rules:

- Feature code depends on repository interfaces, not concrete storage.
- Chrome and macOS clients select adapters during startup.
- Storage methods return `Result` for expected failures.

### `packages/sync`

Owns remote data loading and sync orchestration.

Suggested modules:

- `default-config-client`
- `public-calendar-sync`
- `sync-scheduler`
- `schema-version`

Rules:

- Sync should fetch typed JSON or a documented API format.
- Do not expose remote database implementation details to UI code.
- Persist last sync timestamps through the storage package.

### `packages/ui`

Contains shared React UI if both clients use a web UI surface.

Suggested modules:

- `calendar-view`
- `date-detail`
- `mark-editor`
- `diary-editor`
- `settings-panel`
- `shortcut-help`

Rules:

- Components receive data and callbacks through typed props.
- Components do not import storage or sync adapters.
- Shell-specific UI, such as Chrome popup sizing or macOS window chrome, stays in the app packages.

## Chrome Extension App

Target: Manifest V3.

Main responsibilities:

- Popup entry point.
- Extension service worker.
- Chrome action icon rendering.
- Chrome alarms.
- Chrome storage adapter wiring.
- Runtime messaging between popup and service worker.
- Extension permission declarations.

Suggested modules:

- `src/popup`
- `src/service-worker`
- `src/action-icon`
- `src/runtime-messages`
- `src/app-wiring`

Important behavior:

- Action icon updates when settings change and on schedule.
- The popup reads its data through repositories.
- Service worker performs scheduled sync and icon refresh.
- Runtime messages use typed request and response unions.

## macOS Menu Bar App

Preferred direction: Tauri if React UI reuse is a priority; Swift/AppKit if native UI quality is the priority.

Current implementation status is tracked in `docs/mac-menubar-progress.md`.
The active implementation uses Swift/AppKit, but production UI polish is paused until a formal design is available.

Main responsibilities:

- Menu bar status item.
- Popover calendar window.
- Settings window.
- Local notifications if daily detail reminders are kept.
- Local storage adapter wiring.
- Background refresh of date, moon phase, and public calendar data.

Suggested modules:

- `src/menu-bar`
- `src/popover`
- `src/settings-window`
- `src/local-notifications`
- `src/app-wiring`

Important behavior:

- Menu bar icon shows date or moon phase based on settings.
- Opening the popover shows the same calendar model as Chrome.
- Settings changes update the menu bar icon immediately.
- The popover should remain a compact menu bar tool, not a large application window, unless a formal design specifies otherwise.
- Visual QA is required after layout changes; passing Swift tests is not enough for UI acceptance.

## Data Model Sketch

### Date Keys

Use stable local-date keys instead of JavaScript `Date` objects at module boundaries.

```ts
type LocalDateKey = string & { readonly __brand: "LocalDateKey" };
```

Format: `YYYY-MM-DD`.

### Mark

```ts
type DateMark =
  | { readonly type: "yearly"; readonly month: number; readonly day: number; readonly content: string }
  | { readonly type: "monthly"; readonly day: number; readonly content: string }
  | { readonly type: "oneTime"; readonly date: LocalDateKey; readonly content: string };
```

### Diary

```ts
interface DiaryEntry {
  readonly date: LocalDateKey;
  readonly content: string;
  readonly updatedAt: string;
}
```

### Settings

```ts
interface UserSettings {
  readonly colorScheme: "system" | "light" | "dark";
  readonly showLunarDate: boolean;
  readonly autoOpenTodayDetail: boolean;
  readonly actionIconMode: "date" | "emoji" | "moonPhase";
  readonly showWeekNumbers: boolean;
  readonly showDoubleCalendar: boolean;
  readonly calendarType: "iso8601" | "us" | "arabic" | "hebrew";
}
```

## Testing Strategy

### E2E First

Add E2E coverage before rebuilding each critical flow:

- Chrome popup opens and renders the current month.
- Selecting a day opens the date detail view.
- Creating, editing, and deleting marks updates the calendar.
- Writing a diary entry persists across popup restarts.
- Changing settings updates calendar rendering and icon behavior.
- Scheduled sync stores public calendar data.
- macOS popover opens from the menu bar and renders today's detail.

### Integration Tests

Cover storage and sync boundaries:

- Settings repository with each adapter.
- Marks repository with yearly, monthly, and one-time lookup.
- Public calendar sync with typed fixture data.
- Runtime message handling in the Chrome app.

### Unit Tests

Cover pure logic:

- Lunar conversion known dates.
- Solar term boundary dates.
- Moon phase classification.
- Calendar grid generation.
- Date mark key matching.

## Migration Plan

### Phase 1: Product and Domain Lock

- Finalize this architecture document.
- Define domain types.
- Write fixtures for current public calendar, marks, diary, and settings data.
- Add tests for core calendar behavior before replacing algorithms.

### Phase 2: Shared Core

- Implement `packages/domain`.
- Implement `packages/core-calendar`.
- Replace the large astronomy file with a maintained dependency or isolated vendor module.
- Add unit tests for lunar, solar term, and moon phase behavior.

### Phase 3: Storage and Sync

- Implement repository interfaces.
- Implement Chrome storage and IndexedDB adapters.
- Implement macOS local storage adapter.
- Implement typed public calendar sync.
- Add integration tests.

### Phase 4: Chrome Extension

- Create Manifest V3 app.
- Build popup with shared UI and repositories.
- Build service worker for alarms, sync, and action icon updates.
- Add Playwright-based extension E2E tests.

### Phase 5: macOS Menu Bar Client

- Continue the current Swift/AppKit implementation unless the design direction changes.
- Keep the menu bar popover compact and wait for formal design before final visual polish.
- Keep native calendar, storage, settings, sync, lunar, moon phase, and GPS observation logic covered by tests.
- Add macOS smoke tests or automated UI tests where feasible.

### Phase 6: Polish and Release

- Decide whether to keep promotional content.
- Add import/export if needed for existing local user data.
- Prepare release checklists for Chrome Web Store and macOS distribution.

## Resolved Decisions

- **Recommended actions (宜/忌) are removed from the product.** Deleted from the
  macOS client, `packages/{domain,core-calendar,storage,sync}` and
  `apps/chrome-extension`. The legacy Manifest V2 extension under `src/` still
  contains the feature and is intentionally untouched — it is being replaced
  wholesale, so the inventory above still describes it.
- **The approved design for the macOS client is `昼间 Redesign.dc.html`** in the
  `ming's work — Design Foundations` design system (near-monochrome, flat and
  matte, hairline structure). Notably it defines no glass, blur or accent color:
  the popover is a flat opaque `--surface` with a `--line` hairline, and
  `--glass-shine` is `none`. The design has no year/decade/century picker, so
  that screen extrapolates from the month grid's vocabulary.
- **Holiday subscriptions are multi-select, each with its own colour.** The mac
  client models them as `[HolidaySubscription]` (id/sourceId/customURL/colorId/
  enabled) with days stored per subscription id; the single `holidaySource`
  field migrates. Colours are limited to the design system's muted accents —
  it says "never a saturated color" — and the calendar grid stays monochrome:
  colour appears only as small dots, never on the day number. Both clients now
  ship this: the `HolidaySubscription` type lives in `packages/domain`, the iCal
  parser (with `X-WR-CALNAME` name import and shared-prefix stripping) in
  `packages/sync`, so only the rendering is per-client. A custom feed can be
  named, or the name imported from the feed.
- **The 24 solar terms have hand-drawn phenological icons** on the detail page,
  drawn twice from the same geometry — mac as NSBezierPath, Chrome as SVG. The
  design system has no icon for them, so they extrapolate from its hairline
  vocabulary. They are judged at their real 24pt size, capped at 6
  strokes, and asserted pairwise-distinct.

## Client Parity

The two clients are now close. Chrome was an early ~950-line skeleton at
`mac-v2.0`; it has since caught up on the design system and the product features,
consuming the shared packages for the logic. Current state:

| | macOS | Chrome |
| --- | --- | --- |
| Size | ~5,800 lines (Swift) | ~2,700 lines (TS) + shared packages |
| v2 plain design system | applied | applied |
| Dark mode | yes | yes |
| Localisation | zh / en / th | zh / en / th |
| Holiday subscriptions | multi-select, per-source colour, custom iCal + name | same |
| Solar terms | text + 24 hand-drawn icons (NSBezierPath) | text + the same 24 as SVG |
| Moon | status icon + row + flat card + 3D panel | browser-action icon + flat card |
| Detail panel | holidays, solar term, moon, marks, diary | same |
| Shell | menu-bar status item, configurable segments, status editor | browser-action icon, service worker |

What is genuinely NOT shared, and why:

- **The 3D moon panel is macOS-only, by decision** — it is SceneKit and does not
  port to a web popup; Chrome shows the flat SVG disc only.
- **The shell differs by platform** — a macOS menu-bar status item with a
  configurable segment editor vs. a Chrome browser-action icon and MV3 service
  worker. Not a gap to close; they are different surfaces.
- Most of the macOS size lead is that mac-only code: the 3D SceneKit panel, the
  status-bar segment editor, and the CoreLocation moon-observation astronomy.

The holiday feature is the model for how shared logic should live: the
`HolidaySubscription` type is in `packages/domain`, the iCal parser in
`packages/sync`, the repositories in `packages/storage` — only the rendering is
per-client (AppKit vs DOM). The one thing the clients still duplicate is the
solar-term GLYPHS (Swift NSBezierPath and TS SVG draw the same geometry twice),
because one is Swift drawing and one is web SVG; the coordinates could be shared
as data if it ever seems worth it.

Two cautions when changing shared or cross-client code:

- **A macOS UI fix is usually AppKit-specific** (constraint order, `cornerRadius`
  clamping, appearance resolution) and has no Chrome equivalent — but a fix in a
  shared package (e.g. `formatLunarDateZh` emitting a raw solar-term enum) affects
  both, so check the other client.
- **The clients handle a missing settings key differently.** Chrome's
  `parseSettings` falls back per field, so it never had the "one missing key
  resets every setting" bug that `UserSettings` had in Swift; macOS needed a
  custom decoder. Adding a field is safe on Chrome, needs the decoder on macOS.

The design doc specifies the Chrome popup in its own right — section
"01 · 浏览器插件弹窗" — so Chrome's target is defined, not improvised.

## Open Decisions

- Is the current Swift/AppKit direction final, or should macOS move back to a shared React/Tauri UI after design?
- Should user marks and diary entries remain local-only or sync across devices?
- Should public calendar data come from a new typed API instead of replicated databases?
- Should promotional content be removed from the rewrite?
- Should existing local PouchDB data be migrated, exported manually, or intentionally discarded?

## Recommended First Implementation Slice

Build a minimal vertical slice:

1. `packages/domain` with strict date, settings, mark, and diary types.
2. `packages/core-calendar` with calendar grid and lunar display for one month.
3. `apps/chrome-extension` popup that renders the current month from shared core.
4. E2E test that opens the popup and verifies today's date, lunar text, and settings-driven week numbers.

This slice proves the shared architecture before spending time on macOS, sync, or advanced settings.
