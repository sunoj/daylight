# Mac App Store release

Submitted on 2026-09-24 for the personal developer account, with free pricing confirmed by the owner.

## Identity and artifacts

- Seller: Ming Sun; team `JHH9GC8Y8C`.
- Bundle identifier: `com.mings.daylight` (Apple resource `M7YW9A5HJQ`).
- Provisioning profile: `Daylight Mac App Store` (`JCLBJ4SZNF`).
- Application signing identity: `Apple Distribution: Ming Sun (JHH9GC8Y8C)`.
- Installer signing identity: `3rd Party Mac Developer Installer: Ming Sun (JHH9GC8Y8C)`.
- Current store version: `2.0.3`, build `1` (replaces the earlier 2.0.1 and 2.0.2 submissions).
- Package: `apps/mac-menubar/dist/app-store/Daylight-2.0.3-1.pkg`.
- Listing metadata and review notes: `assets/store/mac-app-store/listing.json`.
- Screenshots: `assets/store/mac-app-store/screenshots/{en-US,zh-Hans}`.

Signing secrets and the provisioning profile are stored outside the repository under `~/.appstoreconnect/daylight-signing/`. No credentials belong in source control.

## Build

```bash
bash apps/mac-menubar/scripts/package-app-store.sh
```

The script builds ARM64 and Intel binaries with the installed SDK, combines them, enables the App Sandbox, embeds the profile and privacy manifest, signs with the personal account, and creates a signed installer. It does not replace the local development app or the company-signed website release. `APP_STORE` builds exclude the Sparkle updater and hide its settings action.

Sandbox permissions cover outgoing holiday feed downloads, user-selected diary export files, calendar access and optional location access. The privacy manifest declares local UserDefaults storage and no collected data or tracking.

Regenerate store screenshots from actual AppKit views using isolated demo storage:

```bash
DAYLIGHT_STORE_SCREENSHOTS="$PWD/assets/store/mac-app-store/screenshots" \
swift test --package-path apps/mac-menubar -j 2 --filter AppStoreScreenshotExportTests
```

## Submission state

Version `2.0.1` was submitted on 2026-09-24 at 03:57:17 UTC, then canceled before review for Traditional Chinese support. Version `2.0.2` was submitted at 05:21:32 UTC, then canceled before review to remove the retired remote config request. Version `2.0.3` (build `1`) was uploaded, processed as `VALID`, and submitted at 06:41:49 UTC. App Store Connect confirmed `WAITING_FOR_REVIEW` with zero blockers. Pricing remains free in all 175 configured territories, and release is set to `AFTER_APPROVAL`.

- App ID: `6815507768`.
- Version ID: `517d06b7-a5ed-412b-a411-9651110cff8b`.
- Build ID: `cfdc1fb0-0341-4802-8b87-35a200b93cb7`.
- Review submission: `08ec415d-c0e1-4eae-8e90-bb7115fa630f`.
- [App Store Connect](https://appstoreconnect.apple.com/apps/6815507768/appstore).
- Public URL after approval: `https://apps.apple.com/app/id6815507768`.

English and Simplified Chinese descriptions, app names, subtitles, support/privacy URLs, and three screenshots per locale are saved. All six screenshot assets reached `COMPLETE`. Review contact was reused from an existing app in the same personal account; no credentials are required to review Daylight. The no-data-collected privacy declaration is published. Primary/secondary categories are Productivity and Utilities; the age-rating questionnaire has no objectionable content categories enabled.

The owner confirmed Daylight is a personal, noncommercial project with no profit intent and saved the non-trader declaration in App Store Connect on 2026-09-24. The account was then checked again: `pending=false`, with no outstanding DSA notice. Both developer agreements are active. The declaration required a manual UI step because the CLI has no DSA setter and browser/computer control was unavailable.

API operations use profile `GoldGood`, belonging to personal team `JHH9GC8Y8C`. Web login uses numeric provider ID `122223253` (public provider ID `8099100b-af06-423e-bc8d-10f5eec00ee9`); the developer Team ID is not the web provider selector. The checksum-verified CLI used for submission is `/tmp/daylight-asc-5.4.0`.

Pre-submission deep validation had zero substantive metadata or build issues. Remaining warnings were the initial release's non-editable What's New fields and an agreement-status detection warning. Both developer agreements were separately verified active. The replacement submission's status check reported zero blockers. Only Apple review remains outstanding; this is submitted, not yet approved or publicly released.

## Verification

- The latest native suite ran 173 tests with zero failures; the opt-in screenshot export was skipped in that run and separately verified with a Traditional Chinese screenshot.
- Mainland China feeds preserve adjusted workdays. Both clients display a workday badge independently of the lunar-date setting; parser, feed integration, and Chrome grid regression tests passed.
- Universal binaries target macOS 13 and record macOS SDK 27.0.
- Application signature verification and signed installer verification passed.
- Screenshot export is opt-in and uses no personal calendar events or diary entries.
- English layout fixes keep the compact month title, day details, and Save label visible. Six 1280×800 English and Simplified Chinese screenshots were rendered and inspected.

Apple references: [macOS distribution signing](https://developer.apple.com/documentation/xcode/creating-distribution-signed-code-for-the-mac/), [Mac installer packaging](https://developer.apple.com/documentation/xcode/packaging-mac-software-for-distribution), [required-reason API declarations](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype).
