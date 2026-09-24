# Daylight product site

Static marketing site for Daylight (昼间). No build step, no runtime dependencies.

**English is the default** at `/`. Simplified Chinese, Traditional Chinese, and Thai live at `/zh/`, `/zh-hant/`, and `/th/`. All four locales share one `styles.css`, `favicon.svg`, and `fonts/` directory — update copy in every locale when content changes.

## Local preview

Open `index.html` in a browser, or serve the directory:

```bash
cd apps/site
python3 -m http.server 8080
```

Then visit:

- http://localhost:8080 — English (default)
- http://localhost:8080/zh/ — Simplified Chinese
- http://localhost:8080/zh-hant/ — Traditional Chinese
- http://localhost:8080/th/ — Thai

The pages load only local assets (CSS, self-hosted IBM Plex fonts, favicon). Store links are ordinary `<a href>` navigation, not third-party embeds. There is no `Accept-Language` redirect and no language cookie — users switch locale via the header/footer links.

Every page links to the public source repository at `https://github.com/sunoj/daylight` in its footer. Publish that link only after the repository is public.

## Deploy to Cloudflare Pages

1. In the Cloudflare dashboard, create a Pages project connected to this repository (or upload the folder manually).
2. Set **Build command** to empty / none.
3. Set **Build output directory** to `apps/site`.
4. Deploy. `_headers` is applied automatically for cache and security headers.

For a custom domain, attach it in the Pages project settings after the first deploy.

## Releasing the Mac app

The download links and the Sparkle appcast are served from this same Pages
deploy — `daylight.mings.work` is a Pages project, so an R2 bucket cannot be
bound to that hostname, and the feed URL compiled into every shipped build
points here.

Cut a release from `apps/mac-menubar`:

```bash
SPARKLE_EDDSA_KEYCHAIN_ACCOUNT="daylight Sparkle EdDSA Key" NO_GH_RELEASE=1 \
  scripts/release-macos.sh --notarize --profile cmview-notary
```

Then stage the artefacts into this directory and deploy:

```bash
cp ../mac-menubar/dist/daylight-<version>-macos.dmg .
cp daylight-<version>-macos.dmg daylight-macos.dmg
cp ../mac-menubar/dist/appcast/appcast.xml .
cp ../mac-menubar/dist/appcast/*.delta .
npx wrangler pages deploy . --project-name=daylight --branch master
```

The production branch is `master`; deployments to `main` are previews. Stage every enclosure referenced by `appcast.xml`: the latest full release and the generated deltas from older installed versions. Check each enclosure length against its file before deployment. Retired full installers should stay out of the site directory.

Two copies on purpose: Sparkle's appcast enclosure needs the exact versioned
file per update, while the site links to the stable `daylight-macos.dmg` so the
HTML never changes between releases. Both are gitignored — they are build
outputs, not source.

The release script regenerates the feed from the DMGs present and publishes only the newest item, while retaining deltas from older installed versions. Always verify the versioned download URL, signature, and file size after deployment.

## Files

| Path | Purpose |
|------|---------|
| `index.html` | English landing page (default, served at `/`) |
| `zh/index.html` | Simplified Chinese page |
| `zh-hant/index.html` | Traditional Chinese page |
| `th/index.html` | Thai page (Buddhist Era in app screenshot) |
| `images/` | Actual app screenshots with isolated demo data |
| `support.html`, `zh/support.html`, `zh-hant/support.html`, `th/support.html` | Localized help and contact pages |
| `styles.css` | Shared design tokens, layout, component styles |
| `fonts/` | Self-hosted IBM Plex Sans VF and Mono (copied from `apps/mac-menubar`) |
| `favicon.svg` | Favicon derived from `assets/app-icon.svg` |
| `404.html` | Prevents retired download URLs from falling back to the homepage |
| `_headers` | Cloudflare Pages HTTP headers |

Product terminology on the site matches `apps/mac-menubar/Sources/DaylightMenuBar/Localization.swift`. Marketing prose is written idiomatically per locale.

## Licence

Site copy describes the Daylight product, which is licensed under GPL-2.0. Contact: hi@mings.work
