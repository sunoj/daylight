# Store assets

Listing images for the browser extension. The two stores do not take the same
files, so the sets are not interchangeable.

| | Chrome Web Store | Edge Add-ons |
|---|---|---|
| Icon | `chrome/store-icon-128.png` — 128×128, artwork 96×96 with 16px transparent padding | `edge/logo-300.png` — 300×300 |
| Screenshots | 5 maximum | 6 |
| Alpha channel | rejected — every file except the icon is 24-bit RGB | not restricted |
| Small tile | 440×280 | 440×280 |
| Large tile | 1400×560 (`marquee-…`) | 1400×560 |

`shared/listing-copy.txt` holds the description in Chinese and English and the
search terms, with their character and word counts against the store limits.

## Regenerating

The screenshots are real captures of the extension running, at 3× — not
mockups. The lunar dates, solar terms and moon phase in them are computed
output, which is the point: they cannot drift from what the product does.

To reshoot after a UI change:

1. Add a temporary harness under `apps/chrome-extension/audit/` that imports
   `renderPopup` / `renderPopupScreen` and mounts one screen at the popup's real
   398px width, keyed off query parameters for language, theme and screen.
2. Serve it with vite and screenshot each screen with headless Chrome at
   `--window-size=398,620 --force-device-scale-factor=3`.
3. Composite those onto the 1280×800 / 1400×560 / 440×280 canvases.
4. Delete the harness — it is not part of the extension.

Two things that will otherwise bite:

- The app stylesheet pins `html, body` to 398px with `overflow: hidden`. A
  harness page must override all three or the frame is silently clipped and the
  screenshots come out with their right edge cut off.
- Chrome rejects PNGs with an alpha channel for everything except the icon.
  Check the IHDR colour type (2 = RGB, 6 = RGBA); it is not visible by eye.
