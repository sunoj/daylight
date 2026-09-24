# Daylight

Daylight is a free, local-first calendar for the macOS menu bar and Chrome or Edge. It shows lunar dates, the 24 solar terms, moon phases, public holidays and adjusted workdays alongside daily notes and todos.

The [website](https://daylight.mings.work) offers English, Simplified Chinese, Traditional Chinese, and Thai pages. Both clients provide the same four interface languages.

## Get Daylight

- [Download the signed macOS app](https://daylight.mings.work/daylight-macos.dmg) (macOS 13 or later, Apple silicon and Intel)
- [Chrome Web Store](https://chrome.google.com/webstore/detail/%E6%98%BC%E9%97%B4%E6%97%A5%E5%8E%86/fdpfnfidhlijopfejncgamefcoemjboe)
- [Microsoft Edge Add-ons](https://microsoftedge.microsoft.com/addons/detail/%E6%98%BC%E9%97%B4%E6%97%A5%E5%8E%86/dleejdlchigadggmnpaiagaejagmakpg)

The store versions may lag behind the source and direct macOS download while reviews are pending.

## Source layout

| Path | Purpose |
| --- | --- |
| `apps/mac-menubar/` | Native Swift menu bar app |
| `apps/chrome-extension/` | Manifest V3 browser extension |
| `apps/site/` | Static product website |
| `apps/holidays-ical/` | Public holiday iCal feed |
| `packages/` | Shared calendar, storage, and sync code |
| `src/` | Legacy browser extension source, kept for reference |

## Build and test

The native app uses Swift Package Manager. The browser extension uses Node.js and Vite.

```bash
swift build --package-path apps/mac-menubar
swift test --package-path apps/mac-menubar
npm install --legacy-peer-deps --ignore-scripts --no-package-lock
npm test
npm run rewrite:typecheck
cd apps/chrome-extension && npx --yes vite@5.4.20 build
```

The extension build is written to `apps/chrome-extension/dist/`. See [the site README](apps/site/README.md) for local preview and deployment details. Signing, notarization, and App Store packaging require your own Apple developer credentials; those credentials are not part of this repository.

## Privacy

Calendar calculations, notes, and todos are local. Holiday subscriptions download their selected public iCal feeds. The macOS app reads system calendars only when authorized and uses location only for the optional 3D moon view. See the [privacy policy](https://daylight.mings.work/privacy).

## License and contact

Daylight is released under [GPL-2.0](LICENSE). Bundled font and lunar-model credits are in [third-party notices](THIRD_PARTY_NOTICES.md). For support, email [hi@mings.work](mailto:hi@mings.work).
