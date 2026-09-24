# Release status

As of 2026-09-24. Supersedes the release notes in `mac-menubar-progress.md`,
which describes the state as of June and is stale.

## macOS 2.0.3 — released

Live and verified against the published files, not local build output:

The direct release is universal (Apple silicon and Intel), version `2.0.3`, build `202609241334`. The live DMG is 15,338,421 bytes; SHA-256: `ba9f15f700f5a5d88423866a434190d935bd08d65f632fb6dd0baa4c41c93e72`. It removes the retired remote default-config request; holiday subscriptions continue to refresh from their selected iCal sources. The preceding 2.0.2 release added Traditional Chinese. The website has four locales, including `/zh-hant/` with an actual Traditional Chinese app screenshot. The Sparkle feed publishes only the current full installer, plus signed deltas for older installed versions. Retired full installers were removed from the site.

The separate personal-account Mac App Store 2.0.3 build is **WAITING_FOR_REVIEW**, with free pricing and automatic release after approval. The earlier submissions were replaced before review. See [the App Store release record](mac-app-store-release.md) for IDs and the completed DSA declaration.

- `https://daylight.mings.work` — download button live in all four locales,
  pointing at the stable `daylight-macos.dmg` so a future release replaces one
  artefact instead of editing nine links.
- Signed with Developer ID (Team `YX8SMYQJ6U`), notarized, and stapled to
  **both** the DMG and the app inside it.
- Sparkle armed. Feed `https://daylight.mings.work/appcast.xml`, public key in
  `packaging/SparklePublicEDKey.txt`. The private key exists only in the login
  keychain under the account `daylight Sparkle EdDSA Key` — losing it means
  existing installs can no longer verify an update.

Notarization uses the **existing `cmview-notary` keychain profile**, which
belongs to the same Apple account. No Daylight-specific profile was ever
needed, and the App Store Connect API key downloaded during setup went unused;
it is stored at `~/.appstoreconnect/private_keys/AuthKey_BY9CPH28MD.p8` (0600).

To cut another release:

```bash
cd apps/mac-menubar
SPARKLE_EDDSA_KEYCHAIN_ACCOUNT="daylight Sparkle EdDSA Key" NO_GH_RELEASE=1 \
  scripts/release-macos.sh --notarize --profile cmview-notary
```

Then stage into the site and deploy — see `apps/site/README.md`.

### Verifying a release

Download the **live** file and check the app *inside* the DMG, not just the
image. Both must staple:

```bash
curl -sO https://daylight.mings.work/daylight-macos.dmg
spctl -a -vvv -t install daylight-macos.dmg          # accepted / Notarized Developer ID
hdiutil attach -nobrowse -quiet daylight-macos.dmg -mountpoint /tmp/m
xcrun stapler validate /tmp/m/Daylight.app           # must say it worked
hdiutil detach /tmp/m -quiet
```

The second check exists because the first release passed everything else while
the inner app carried no ticket — invisible online, a failed first launch
offline. Fixed in the script; the check stays because the failure is silent.

## Browser extension 0.4.4 — built, not submitted

Not uploaded to either store yet. Everything needed is prepared.

Version 0.4.4 was packaged on 2026-09-24. It removes the retired remote default-config request while preserving scheduled holiday-subscription refresh. Version 0.4.3 added Traditional Chinese UI, calendar and holiday labels, and a `zh_TW` store locale. Version 0.4.2 added the detailed three-color
botanical solar-term icons, hides solar-term artwork when lunar dates are
disabled, distinguishes the selected date, fixes today's text/background
contrast, and displays mainland China adjusted workdays with a separate badge.
The updated holiday feed is deployed; existing subscriptions can be refreshed
to import workdays. No additional extension permissions were added.

Release validation: all 25 workspace test files and all rewrite TypeScript
checks passed. The ZIP contains 24 entries, with `manifest.json` at its root;
archive integrity, entry points, icons, and all four locales were verified.

Since the published 0.3.0:

- diary gained `[]` todos, two-click delete, and a date-aware placeholder,
  matching the macOS client
- the month title opens the month/year/decade/century pickers
- the dual month view was removed outright
- the calendar header is localized (it hardcoded `toLocaleString("en-US")`)
- the About screen's Chinese copy was written; it had been rendering
  translation keys because `t()` returns its argument for Chinese
- greys, gutters and the type scale fixed after a UI audit
- store listing localized via `_locales` (zh_CN, zh_TW, en, th)
- the toolbar icon follows the toolbar theme again. `matchMedia` does not
  exist in an MV3 service worker, so the worker always drew the light-theme
  near-black glyph, invisible on a dark toolbar. The popup now reports
  `prefers-color-scheme` and the worker persists it; before the first popup
  open the glyph is a neutral grey that reads on either toolbar.
- host permissions: the retired default-config host was removed, and
  `daylight-holidays.pages.dev` was replaced by `holidays.mings.work`.
  Net one fewer host and no new capability — worth saying in the submission
  notes, since a reviewer will compare against 0.3.0.

Build and package:

```bash
cd apps/chrome-extension && npx --yes vite@5.4.20 build
(cd dist && zip -qr ../../../daylight-extension-0.4.4.zip . -x '.*' '*/.*')
```

Listing images and copy: `assets/store/` (see its README — the two stores take
different files).

## Open items

1. **Upload to Edge and Chrome.** The privacy/permission justification answers
   are in `assets/store/shared/listing-copy.txt` plus the notes below.
2. **Thai privacy policy** (`/th/privacy`) is a careful translation but has not
   been read by a native speaker. Worth one before relying on it legally.
3. **Thai store screenshots** were not produced; only zh and en.
4. **Local wrangler is broken** — missing `miniflare`, collateral from the
   dependency surgery needed to build the extension. Deploys work by running
   npx from outside the repo:
   `cd /tmp && npx --yes wrangler@3.114.17 pages deploy <abs path> --project-name=daylight`

## Known intermittent

`swift test` failed once with 1 of 162 during handoff checks and has passed 18
consecutive runs since (6 full suites, 8 of the motion suite, plus 4 ad-hoc). I
could not reproduce it, so the offending case is unidentified — the run that
failed had already scrolled past by the time I looked.

Prime suspect is `PopoverMotionPlaybackTests`: two of its cases assert on
CoreAnimation state, and `testTransitionRemovesItsOverlayAndRestoresTheRootStack`
waits a fixed 0.6s for a 0.24s animation's completion block to remove the
snapshot overlay. That margin is generous but it is wall-clock, so a starved run
loop could miss it. If it recurs, note the case name before re-running and
replace the sleep with an expectation fulfilled from the transition's own
completion.

## Things that cost time, so they are written down

- **`npm install` cannot complete in this repo.** The postinstall hook fails,
  and past that the legacy React app's dependencies hit ERESOLVE. What works:
  `npm install --legacy-peer-deps --ignore-scripts --no-package-lock`, which
  leaves `yarn.lock` untouched and writes no lockfile. It also drops
  `miniflare`, hence the wrangler note above.
- **`npm run rewrite:typecheck` exits non-zero on a clean checkout** — the
  errors are inside `node_modules/@types/pouchdb-*`, from the legacy app. Only
  error lines pointing at `packages/` or `apps/` matter.
- **`npm test` runs 25 files and reports each by name.** Most print nothing on
  success, so a silent pass and a file that never ran look identical; the
  per-file line is deliberate. It shells out to tsx through npx rather than a
  pinned devDependency, because adding one breaks the install.
- **The extension's tsconfig sets `"types": []`.** Without it, tsc loads every
  `@types/*` in node_modules and `@types/chrome` collides with the project's own
  `chrome-api.d.ts`. This only surfaces once dependencies are installed.
