# macOS Menu Bar Client — UI/UX Audit

Audit date: 2026-09-26. Build: `master` at `00dd5f0` (2.0.4). Scope: every popover screen of `apps/mac-menubar`.

---

## 1. Summary

The two home screens (Luna, Sol) and all settings sub-pages render cleanly in the default state. Layout, typography and the light/dark palette are coherent across four languages. The defects appear under content load:

- **One long diary note stretches the popover to 717pt wide.** Luna is designed for 300pt and Sol for 412pt. This was reproduced in a real `NSPopover`, not only in the offscreen harness.
- **Once there are more than four or five diary notes, the remaining rows collapse onto each other** and cannot be read.
- Settings and the system-calendar list grow without a scroll container. Settings is already 854pt tall, and the system-calendar page grows about 40pt per calendar.

Localization is complete by key, but some strings bypass `L()`. Those strings show Chinese in the English and Thai UIs, and English in the Chinese UI.

## 2. Method and coverage

The popover was rendered headlessly from a throwaway XCTest into an offscreen `NSWindow`. The matrix was 16 screen states × 4 languages (zh, zh-Hant, en, th) × light/dark, 128 captures in total. Captures were inspected as per-screen contact sheets and zoomed crops. Width and height were read from the laid-out root view. The two sizing findings were then confirmed with a real `NSPopover` shown from an off-screen anchor window.

States covered:
- Luna: default, lunar off, composing, 9 notes.
- Sol: month, year, decade and century views, plus 9 notes.
- Sub-pages: Settings, System calendar, Status bar editor, Location prompt, 3D moon, and Holidays with and without a subscription.

| Area | Rendering | Interaction | Notes |
|---|---|---|---|
| Luna / Sol home, all view modes | pass (with findings) | unverified | Clicks, keyboard shortcuts and hover were not exercised |
| Settings and sub-pages | pass (with findings) | unverified | |
| 3D moon | **unverified** | unverified | `SCNView` does not draw through `cacheDisplay`; the scene card is blank in captures |
| Diary under load | **fail** | unverified | F1, F2 |
| Real popover sizing | fail | n/a | F1 confirmed via `NSPopover` |

Not covered:
- VoiceOver
- Increase Contrast and Reduce Transparency
- Real wallpaper behind the translucent dark `popoverBackground` (alpha 0.70)
- Popover placement on a short display
- The menu bar status item itself
- Transitions and animation
- The calendar-permission states other than *authorized*. The test process has calendar access, so the not-determined and denied states were not rendered.

## 3. Findings

| # | Pri | Finding | Evidence | Cause |
|---|---|---|---|---|
| F1 | **P1** | One long diary note widens the whole popover. The measured width was 717.5pt for Luna (designed for 300) and 715.5pt for Sol (designed for 412). The month grid, the header and every other section stretch with it. Any note longer than about 40 characters triggers it. | Real `NSPopover`: `contentSize=(717.5, 630)` with 9 notes vs `(300, 514)` with one short note. Every language and appearance. | `DiaryThoughtTimelineView.thoughtRow`: the wrapping label (`maximumNumberOfLines = 0`) has no `preferredMaxLayoutWidth`, so its intrinsic width is the unwrapped line. `document.width == scroll.contentView.width` then carries that width out to the popover. |
| F2 | **P1** | With more than about 5 notes, the notes after the fourth are squashed into overlapping rows. Their time labels, checkboxes and delete buttons stack on top of each other, and their text is not visible at all. The list does not scroll to them. | Real popover capture, 9 notes; Luna and Sol, every language. | The `hug` constraint (`scroll.height == document.height`, `.defaultHigh` = 750) ties with the labels' default vertical compression resistance (750). Auto Layout can satisfy it by compressing rows instead of capping the scroll view and scrolling. |
| F3 | P2 | Settings is 854pt tall with no scroll container. On a display whose usable height is below about 860pt (for example a 1280×800 panel, a larger-text scaled resolution, or a docked Stage Manager layout), the bottom rows fall off-screen, including *Check for updates* and *Quit*. | Rendered size 412×854 in all locales. | `CalendarSettingsPanel` sits in a plain stack; `sizeToFit` passes the full fitting height to the popover. |
| F4 | P2 | The System calendar page grows about 40pt per calendar and has no scroll container. With 11 calendars it is 710pt tall; about 15 calendars exceed a 900pt screen. | 412×710 with 11 calendars. | `SystemCalendarPanel` contains no `NSScrollView`. |
| F5 | P2 | The Sol moon row is untranslated: it shows `75% 照亮 · 月龄 9.8d` in English, Thai and Traditional Chinese. The 3D moon page renders the same line localized. | Sol contact sheet, all locales. | `MoonPhasePanel.swift:74` builds the string without `L()`. The keys already exist (`Localization.swift:135-136`). |
| F6 | P2 | Location failure reasons are hardcoded English. The 3D moon status line can show "Location permission is disabled" or "Location lookup failed" inside the Chinese and Thai UIs. | Code: statuses are displayed verbatim by `Moon3DPanel.statusText`. | `LocationService.swift:58,60,102,114`: `.unavailable("…")` literals never go through `L()`. |
| F7 | P2 | Text drawn in `ink4` is at 1.7–2.4:1 contrast, below even the 3:1 large-text bar. It is used for informational text in 7 places, such as the holiday footer (`订阅节假日 · 12`), the moon status line and the agenda count. `ink3` (2.8–4.2:1) carries 15 more text uses, such as section labels and diary timestamps. | Palette matrix: `#B3B2AC` on `#FFFFFF` 2.1:1; `#54534F` on `#1E1E1C` 2.2:1. | Tokens intended for disabled or decorative use are used for readable text. |
| F8 | P2 | Dismiss vocabulary is inconsistent. Settings, System calendar and Holidays close with **×**; the 3D moon and the Status bar editor go back with **‹**. The Status bar editor and System calendar are sibling sub-pages of Settings but use different controls. | Captures of each page. | `closeButton()` (xmark) in three panels; `chevron.left` in `StatusBarEditorPanel.swift:197` and `Moon3DPanel.swift:78`. |
| F9 | P2 | In the location prompt the primary button label (13pt) is smaller than the secondary "Not now" (about 15pt), which inverts their visual weight. In dark mode the secondary button's outline and the two info chips almost disappear. | Location-prompt contact sheet. | `LocationPromptPanel` button styles. |
| F10 | P3 | The Settings title badge is hardcoded as `v2.0` while the app is 2.0.4. The Version row reads the bundle correctly. | `CalendarSettingsPanel.swift:102`: `pill("v2.0")`. | Literal. |
| F11 | P3 | In dark mode the off-state track of the *Launch at login* switch is close to the card colour, so the control reads as missing. | Settings dark captures. | Toggle off-track colour vs `surface`. |
| F12 | P3 | The location prompt shows a sheet-style grab handle at the top, but a popover cannot be dragged, so the handle suggests an interaction that does not exist. | Location-prompt captures. | Decorative bar in `LocationPromptPanel`. |
| F13 | P3 | The app name is inconsistent in zh and zh-Hant: the location prompt says 「昼间」/「晝間」, while Settings says *退出 Daylight*. | Captures. | Mixed strings. |
| F14 | P3 | The System calendar page repeats its subtitle ("选择要显示的日历") as the first section label directly below it. EventKit source names (*Other*, *Subscribed Calendars*, *iCloud*) appear upper-cased in English regardless of app language. | Captures. | Source titles come from the OS locale. |
| F15 | P3 | The holiday footer (`订阅节假日 · 12`) is left-aligned in zh and zh-Hant but right-aligned in en and th. | Holidays contact sheet. | Locale-dependent alignment in the footer row. |
| F16 | P3 | The Luna header shows the lunar month of the 1st of the month (`丙午年 · 七月`), while most of the grid and the selected day are already in 八月. It is correct but can read as wrong in months that cross a lunar-month boundary. | September 2026 captures. | Design choice; consider showing the range, as the year view does (`七月–八月`). |
| F17 | P3 | The Sunday-column workday badge (`班` / `W`) sits ≤1pt from the Luna panel's right edge. | 6× zoom crop. | Badge offset is outside the cell. |
| F18 | Product | The holiday source list labels Taiwan `中国台湾` / `Taiwan, China` (`HolidayService.swift:33`, `Localization.swift:268`). zh-Hant users will read it as `中國臺灣`. This is a policy decision rather than a UI defect, but it is visible to every Traditional Chinese user. | Holidays captures. | — |

Checked and withdrawn: two apparent Simplified/Traditional mix-ups in the System calendar and Holidays headers were artifacts of downscaling. At full resolution both headers are correct.

## 4. Fix list

Shared-component fixes; cheap and low-risk:

1. **F1 + F2** in `DiaryThoughtTimelineView`:
   - Give the note label a low horizontal compression resistance, or set a `preferredMaxLayoutWidth` from the row width, so that it wraps instead of pushing.
   - Drop the `hug` priority below the labels' compression resistance (for example `.defaultHigh - 1`).
   - Add a regression test that asserts `fittingSize.width == Metrics.lunaPopoverWidth` with a 200-character note and 9 notes.
2. **F5, F6:** wrap the five literals in `L()` and add the four location reasons to `Localization.swift`.
3. **F10:** read the badge from `CFBundleShortVersionString`.
4. **F8:** pick one rule and apply it to both sub-page levels: ‹ for pages pushed from Settings, × for top-level pages.

Layout changes:

5. **F3, F4:** put Settings and the System calendar list in a scroll view capped at the visible screen height (`NSScreen.visibleFrame` minus the popover arrow).

Design-token changes. These affect many views and need a screenshot pass afterwards:

6. **F7, F11:** raise `ink3` to at least 4.5:1 on `surface`, and keep `ink4` for disabled and decorative use only.
7. **F9, F12, F13–F17:** copy and alignment polish.

**F18 is a product decision for the owner.**

## 5. Status (2026-09-27)

Fixed:

- **F1 + F2.** `DiaryThoughtTimelineView`:
  - The note label is now a `DiaryWrappingLabel`. It has no intrinsic width and reports only the height it needs at its laid-out width, so a long note wraps instead of widening the popover.
  - The scroll view's height hug sits one step below `.defaultHigh`, so overflowing notes scroll instead of being squashed.
  - A first attempt that fed `bounds.width` back into `preferredMaxLayoutWidth` locked in a 16pt first-pass width. `DiaryThoughtRowLayoutTests` caught it.
  - Covered by `DiaryThoughtOverflowTests` (Luna and Sol): the popover keeps its designed width with a long note, and with ten notes every row keeps full height, rows do not overlap, the long note wraps, and the list scrolls.
  - A real `NSPopover` now measures 300×584 (Luna) and 412×672 (Sol) with nine notes, down from 717.5 and 715.5 wide.
- **F5.** `MoonPhasePanel` routes `照亮` / `月龄` through `L()`. The English Sol row now reads `98% lit · age 13.5d`.
- **F6.** `LocationService` emits Chinese keys (`定位权限已关闭`, `定位状态未知`, `无法获取位置`, `定位失败`), each with en/th entries. `Moon3DPanel.statusText` localizes them at display.
- **F10.** The Settings badge reads `CFBundleShortVersionString`.

Open: F3, F4, F7–F9, F11–F17, and F18 (the F18 wording is the owner's decision).

## 6. Performance pass and the regression it caused (2026-09-28)

- **Prewarm.** `AppDelegate.prewarmPopover` builds the popover's view tree after launch. The first click went from 194–548ms to 65–86ms. The earlier claim that EventKit caused the slow first open was wrong: EventKit costs about 115ms cold, and that comparison was confounded by launch order.
- **Month grids use frame layout.** `LunaMonthGridView`, `LunaDateCell`, `CalendarMonthView` and `CalendarDateCell` no longer use stack views or Auto Layout. Each render rebuilt about 2,400 constraints.
  - The grid now takes 14.7ms per render instead of 68ms.
  - A Sol month step takes 54/83ms instead of 95/140ms (calendar off/on).
  - `MonthGridLayoutCostTests` fails if the grids pick up constraints again.
  - 112 grid states are pixel-identical to the pre-change renders.
- **Regression, found in the live app and not by tests.**
  - Labels were framed to their exact measured text width. The prewarm measured them before the popover had a window.
  - Drawn in the popover, the same text needed 4pt more. Dates became "…", and three-character holiday names and the 班 badge were clipped.
  - Every offscreen check had measured and drawn under the same conditions, so none caught it.
  - Fix: date and subtitle labels span the cell with centred text, and the badge gets a roomy right-aligned frame. Cells re-lay out on window or backing changes.
  - Verified against in-window measurements logged from the running app.
- **Lesson.** For AppKit layout changes, verify the running app's popover as well as offscreen renders; the two can disagree.
