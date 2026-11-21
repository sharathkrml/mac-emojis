# MacEmojis — release checklist

Status as of **2026-11-21**.

**Scope: source-only open-source release.** The code is public. Binary distribution (notarization, DMG, Homebrew, app icon) is deferred. The detailed checklist below is kept for the later binary release.

**Source-only verdict: ready to publish.** The privacy logging is removed, the clipboard race is fixed, the project builds with ad-hoc signing, the license and Desert Ant attribution are in place, and the public README is written.

**Binary release: not ready.** Still needs a Developer ID signature, notarization, an app icon, and a notarized DMG. See the deferred items below.

## Source-only status

Done in this pass:

- [x] Removed every `NSLog` that could contain typed text.
- [x] Fixed the clipboard restore race.
- [x] `ARCHS=arm64` and a `make release` target that passes it explicitly.
- [x] Pinned Emo to `4.3.0`.
- [x] Ad-hoc signing by default so contributors can build.
- [x] Version set to `0.1.0`; Info.plist uses the build settings.
- [x] MIT `LICENSE`, `THIRD_PARTY_NOTICES.md`, `PRIVACY.md`, `SECURITY.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `CHANGELOG.md`.
- [x] Public `README.md` and GitHub metadata copy.
- [x] About panel with version, Desert Ant credit, GitHub, and issue links.
- [x] CI workflow, issue templates, PR template.
- [x] Removed `.opencode/` from the public tree.
- [x] Added `Inserter` tests: **31 tests, 0 failures**.
- [x] CI passes on `macos-latest` (tests + release build).
- [x] GitHub release `v0.1.0` published with source notes.

Deferred for a binary release:

- [ ] Developer ID Application certificate, hardened runtime, notarization, stapling.
- [ ] App icon and asset catalog.
- [ ] DMG, Homebrew cask, checksums, release assets.
- [ ] Gatekeeper test on a clean Mac.
- [ ] Sparkle or another update path.
- [ ] Privacy manifest and Xcode privacy report.
- [ ] Full manual app matrix and performance/battery pass.

---

## What I verified

| Check | Result |
|---|---|
| `make test` | **31 tests, 0 failures** |
| Debug build | Passes, arm64, ad-hoc signed |
| `make release` | Passes, arm64, hardened runtime on |
| Plain `xcodebuild -configuration Release` without `ARCHS=arm64` | Still fails in the Emo package for x86_64; use `make release` |
| Signature on current build | Ad-hoc (`CODE_SIGN_IDENTITY = -`), no team |
| App icon | **None** — deferred for the binary release |
| Version | **0.1.0** (`CFBundleVersion` 1) |
| GitHub repo | public; description, homepage, topics, MIT license, Discussions, private vulnerability reporting |
| GitHub release | **v0.1.0** source release; no binary assets |
| CI | Passing on `macos-latest` (31 tests + release build) |
| Bundle ID | `com.sharath.MacEmojis` |
| Deployment target | macOS 15.0 |

---

## P0 — block the public release

### 1. Remove logging that records the user's text — DONE

`MacEmojis/Insert/Inserter.swift:7` logs the whole `SuggestionContext`, which contains the typed sentence or selected text:

```swift
NSLog("[DEBUG-hx7] insert context=\(context) emoji=\(emoji)")
```

That goes to the macOS unified log. It defeats the privacy promise.

- [ ] Delete every `[DEBUG-hx7]` log: `MacEmojis/UI/BubbleController.swift` (lines 23, 28, 33, 53, 87, 111, 132, 268) and `MacEmojis/App/AppDelegate.swift:31`.
- [ ] Keep operational logs only if they are useful and contain no text. Prefer `os.Logger` with `.private` interpolation.
- [ ] Check `TextMonitor.swift:67` and `Inserter.swift:52–65`; they log lengths/emoji but are still noise for a consumer app.
- [ ] Verify while typing in a test document:
  ```bash
  log stream --predicate 'process == "MacEmojis"' --style compact
  ```
  No typed words should appear.
- [ ] Verify the source: `grep -rn "DEBUG-hx7" MacEmojis` returns nothing.

### 2. Decide the CPU architecture and fix the Release build — DONE (Apple Silicon)

The default Release config builds `arm64 x86_64`, and the Emo SDK does not compile for x86_64 on macOS 27 SDK. The current Release build cannot ship.

- [ ] Ship **Apple Silicon only** for v0.1, or wait for an upstream Emo/SDK fix and pin it.
- [ ] Set explicitly in `project.yml`:
  ```yaml
  settings:
    base:
      ARCHS: arm64
  ```
  or set `EXCLUDED_ARCHS[sdk=macosx*]: x86_64`.
- [ ] Make the Makefile and README say **Apple Silicon** alongside macOS 15+.
- [ ] Verify:
  ```bash
  make release
  lipo -info build-release/Build/Products/Release/MacEmojis.app/Contents/MacOS/MacEmojis
  # expected: Non-fat file ... architecture: arm64
  ```
  `make release` passes `ARCHS=arm64` explicitly. A plain `xcodebuild -configuration Release` still asks Xcode to build the Emo package for x86_64, which fails.
- [ ] Homebrew cask: `depends_on arch: :arm64`.

### 3. Sign and notarize for real distribution — DEFERRED (binary release)

Current build is signed with an **Apple Development** certificate and `ENABLE_HARDENED_RUNTIME: NO`. A public download will be blocked by Gatekeeper.

- [ ] Join the Apple Developer Program (paid) if not already.
- [ ] Create a **Developer ID Application** certificate.
- [ ] Set `ENABLE_HARDENED_RUNTIME: YES` for Release.
- [ ] Keep `com.sharath.MacEmojis` and the same signing identity across updates so the Accessibility (TCC) grant survives.
- [ ] Notarize the app **and** the DMG, then staple both. Runbook below.
- [ ] Test on a clean Mac or fresh user account: download from GitHub, open, confirm no Gatekeeper warning.
- [ ] Do **not** ship the Apple Development-signed build from `build/`.
- [ ] Decide App Store: **not recommended**. Reading other apps' text through Accessibility is not compatible with App Sandbox and is a likely review rejection. Distribute a notarized DMG from GitHub Releases.

### 4. Add a real app icon — DEFERRED (binary release)

There is no asset catalog and no icon. The app currently shows the generic macOS app icon.

- [ ] Create an original 1024×1024 icon. Do **not** use the 😄 emoji glyph or an SF Symbol as the icon — emoji artwork and SF Symbols are not licensed for app icons.
- [ ] Export the macOS sizes: 16, 32, 64, 128, 256, 512, 1024 (1x/2x).
- [ ] Add `MacEmojis/Assets.xcassets/AppIcon.appiconset`.
- [ ] Set `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` and `CFBundleIconName: AppIcon`.
- [ ] Verify the icon in Finder, Dock (if shown), and the About panel.

### 5. Choose a license and satisfy the Emo license — DONE

The repo has no `LICENSE`; GitHub reports `license: null`. It also uses the **source-available** Emo SDK, which is not OSI open source.

- [ ] Pick a license for your code: **MIT** (simplest) or **Apache-2.0** (patent grant). Add `LICENSE`.
- [ ] Add `THIRD_PARTY_NOTICES.md` covering:
  - Emo / Desert Ant Labs — Source-Available License 1.0, <https://license.desertant.com/>
  - Any Swift package dependencies.
- [ ] Add the required Desert Ant credit in a place users can find. The license asks for a discoverable credit such as:
  > **Powered by [Desert Ant Labs](https://desertant.com/) 🐜**
  
  Put it in Settings/About **and** the README.
- [ ] Read the free-tier terms: free below **100,000 monthly active devices per platform, per model**. Above that you need a commercial license. Track MAU after launch.
- [ ] Consider emailing <licensing@desertant.com> before launch to register the app and confirm the free tier.
- [ ] Phrase the repo honestly: "MacEmojis is open source. It uses the source-available Emo model by Desert Ant Labs." Do not describe the whole dependency stack as OSI open source.

### 6. Disclose the network calls — DONE

The README says "no text ever leaves the Mac," which is true. But the app makes two kinds of network requests that a privacy-focused user will ask about:

1. **Model download** from Hugging Face (`huggingface.co`), one time, ~5 MB.
2. **Emo license check** to `events.desertant.com` when the model loads. It sends a random install ID, bundle ID, model name/version, SDK version, and platform — **not the typed text**.

- [ ] Add a **Privacy** section to the README with the exact data flow.
- [ ] Add `PRIVACY.md` (draft in `docs/LAUNCH_COPY.md`).
- [ ] Confirm no analytics, crash reporting, accounts, ads, or text upload. If you add any later, update the policy first.
- [ ] Document that macOS may keep the emoji briefly on the clipboard when the web-editor paste path is used.

### 7. Fix versioning and add About/Credits — DONE

`MacEmojis/Info.plist` hardcodes `1.0` while `project.yml` says `MARKETING_VERSION: 0.1`. The built app reports 1.0.

- [ ] Pick one version. For a first public release, `0.1.0` (beta) or `1.0.0` (launch). Be consistent.
- [ ] In `Info.plist`:
  ```xml
  <key>CFBundleShortVersionString</key>
  <string>$(MARKETING_VERSION)</string>
  <key>CFBundleVersion</key>
  <string>$(CURRENT_PROJECT_VERSION)</string>
  ```
- [ ] Add `NSHumanReadableCopyright`.
- [ ] Add menu items in `AppDelegate.buildMenu()`: **About MacEmojis**, **Credits**, **Report an Issue**, **Check for Updates** (if implemented).
- [ ] The About panel must show: version/build, Desert Ant credit with link, GitHub link, license.
- [ ] Add an "About" entry point from Settings too.

### 8. Fix the clipboard restore race — DONE

`Inserter.fallbackPaste` saves the pasteboard, writes the emoji, waits ~520 ms, then restores. If the user copies anything in that window, it is overwritten by the old contents.

`MacEmojis/Insert/Inserter.swift:91–101`:

- [ ] Record the change count after your write and only restore if it is unchanged:
  ```swift
  pasteboard.clearContents()
  pasteboard.setString(text, forType: .string)
  let ownChangeCount = pasteboard.changeCount
  ...
  guard pasteboard.changeCount == ownChangeCount else { return }
  pasteboard.clearContents()
  if !saved.isEmpty { pasteboard.writeObjects(saved) }
  ```
- [ ] Test: copy something else immediately after picking an emoji in Chrome/X; the new clipboard content must survive.
- [ ] Add a note to privacy docs that clipboard managers may capture the temporary emoji.

### 9. Commit, tag, and publish — DONE (source release)

Source-only release:

- [x] Commit the working tree.
- [x] Add `CHANGELOG.md` with a `0.1.0` entry.
- [x] Tag `v0.1.0`.
- [x] Create a GitHub Release with `docs/RELEASE_NOTES_0.1.0.md`; no binary assets.

Deferred for the binary release:

- [ ] Notarized `MacEmojis-0.1.0.dmg`
- [ ] `MacEmojis-0.1.0.zip` (optional, for Sparkle)
- [ ] `SHA256SUMS.txt`
- [ ] Verify `spctl` and `stapler` on the uploaded file, not just the local build.

### 10. Replace the developer README and fill GitHub metadata — DONE

The root `README.md` is now the public source-only README. The GitHub About description, homepage, and topics are set with `gh repo edit`.

Still useful:

- [ ] Add a demo GIF/screenshot: bubble over a sentence, `:cake` replace mode, Settings. 3–5 images.
- [ ] Upload a 1280×640 social preview image.
- [ ] Pin the repo on your profile; update your profile bio (copy in `docs/LAUNCH_COPY.md`).
- [x] Enable **Private vulnerability reporting** under Settings → Code security.
- [x] Enable Discussions for questions and ideas.

### 11. Clean the public repo — DONE

- [ ] Remove the 79 tracked `.opencode/skills/*` files from the public repo. They are personal AI instructions, not app source:
  ```bash
  git rm -r --cached .opencode
  printf '\n.opencode/\n' >> .gitignore
  ```
- [ ] Confirm no secrets, certificates, `.p8`, `.mobileprovision`, or personal tokens are tracked.
- [ ] Consider a `.github/` folder: issue templates, PR template, `SECURITY.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`.
- [ ] Add `README`, `LICENSE`, and `PRIVACY.md` links to the repo sidebar.

### 12. Make the repo buildable by contributors — DONE

`project.yml` hardcodes `DEVELOPMENT_TEAM: 83JSBLYT7Z` with manual Apple Development signing. Anyone else's `xcodebuild` fails or has to edit the project.

- [ ] Default to automatic signing with no team committed, or ad-hoc signing (`CODE_SIGN_IDENTITY: "-"`).
- [ ] Document "use your own team" in `CONTRIBUTING.md`.
- [ ] Keep the Developer ID identity and team in CI secrets, not in `project.yml`.
- [ ] Pin `DesertAntCore` to an exact version (or commit a lockfile). `MacEmojis.xcodeproj` is gitignored, so `Package.resolved` is not tracked today:
  ```yaml
  packages:
    DesertAntCore:
      url: https://github.com/Desert-Ant-Labs/desert-ant-core.git
      exactVersion: 4.3.0
  ```

---

## P1 — do before or on launch day

### Distribution and updates

- [ ] Build a DMG with a drag-to-Applications background.
- [ ] Move to `/Applications` before granting Accessibility; document this (App Translocation breaks TCC grants when run from Downloads).
- [ ] Add an update path: Sparkle 2 (EdDSA-signed appcast) or, at minimum, a "Download the latest version" link and a documented manual update process.
- [ ] If using Sparkle, test that an update keeps the Accessibility grant.
- [ ] Homebrew: submit a cask or publish a tap.
- [ ] Uninstall instructions: quit, delete app, remove Accessibility entry, delete `~/Library/Caches/desert-ant-models` and `~/Library/Caches/com.sharath.MacEmojis`, `defaults delete com.sharath.MacEmojis`.

### CI

- [ ] GitHub Actions workflow on `macos-15`/`macos-26` with Xcode 26+:
  ```bash
  brew install xcodegen
  make test
  xcodebuild -scheme MacEmojis -configuration Release ARCHS=arm64 build
  ```
- [ ] Release workflow on tag: import Developer ID cert from secrets, archive, export, notarize, staple, DMG, checksums, `gh release upload`.
- [ ] Dependabot for the Swift package (optional).
- [ ] Protect `main`; require CI on PRs.

### Privacy and security

- [ ] `PRIVACY.md` published (repo and/or website).
- [ ] `SECURITY.md` with private reporting instructions.
- [ ] Add `PrivacyInfo.xcprivacy` (or run Xcode's Generate Privacy Report and act on it):
  - `NSPrivacyTracking` = false, collected data types = empty.
  - Declare `UserDefaults` with reason `CA92.1`.
  - Declare any keyboard-input or file-timestamp APIs Xcode flags.
- [ ] Verify the app makes only the two intended network calls (Hugging Face, Desert Ant) with Little Snitch/mitmproxy while typing. No text in request bodies.
- [ ] Verify secure fields are skipped: 1Password, Bitwarden, Keychain Access, Safari password fields, Terminal `sudo` prompt.
- [ ] Verify `IsSecureEventInputEnabled()` behavior while a password manager has secure input on.
- [ ] Confirm no text is written to disk or logs.
- [ ] Run a clean-machine install test with Gatekeeper.

### Accessibility and quality

- [ ] VoiceOver pass over onboarding, Settings, and the bubble. Chips have labels; verify keyboard-only engagement (←/→/Enter/Esc).
- [ ] Respect **Reduce Motion** in the bubble (`BubbleView`, `BubbleController` animations currently ignore it).
- [ ] Test Increase Contrast and 200% zoom.
- [ ] Test RTL and a non-US keyboard layout.
- [ ] Test skin tones across all suggestions.
- [ ] Test the 150-character cap and multi-line fields.
- [ ] Test `:token` replacement at the start, middle, and end of text; test `12:30` stays plain.
- [ ] Test selection mode on/off.
- [ ] Add a unit test for `Inserter.composedText` (space-before-emoji rules); that helper is currently untested.
- [ ] Test with the model not downloaded, download in progress, download failed, offline, and corrupted cache.
- [ ] Test permission denied, granted later, revoked while running.
- [ ] Test sleep/wake, multi-monitor, Spaces, full-screen, Stage Manager.
- [ ] Measure idle CPU and battery with the 5 Hz Accessibility poll; run Instruments for a few hours.
- [ ] Fix the `NSScreen.screens[0]` potential crash in `BubbleController.placement` if there is any chance of no screens.
- [ ] Fix the `weak self` warning in `EmoService.swift:93`.
- [ ] Decide whether confidence scores (0.00–1.00) belong in the consumer UI. They are unusual for users; consider hiding them behind a "Show confidence" advanced setting.

### Manual app matrix

Test typing, the bubble, insertion, and undo/backspace in at least:

- [ ] TextEdit, Notes, Messages, Mail
- [ ] Safari, Chrome, Brave, Firefox
- [ ] Slack, Discord, X/Twitter, Gmail
- [ ] VS Code, Cursor, Terminal, iTerm2
- [ ] Notion, Linear, Obsidian
- [ ] Google Docs canvas and Figma (document as unsupported)
- [ ] Microsoft Word and Pages
- [ ] Password fields and secure input

### Legal and naming

- [ ] Review the name **MacEmojis**. Apple's trademark guidelines discourage putting Apple product names (`Mac`, `iPhone`) in app names. Many indie apps do it, but confirm before buying a domain or printing merchandise; a neutral name avoids the argument.
- [ ] Check the name is available on GitHub, the Mac App Store (if ever), X/Bluesky, and a domain.
- [ ] Keep the Emo attribution visible after any rename.

### Docs and support

- [ ] `CONTRIBUTING.md` with build, test, signing, and PR expectations.
- [ ] `CODE_OF_CONDUCT.md` (Contributor Covenant is fine).
- [ ] Issue template: bug report asks for macOS version, app version, target app, steps, logs (with no text).
- [ ] FAQ / troubleshooting in the README.
- [ ] `CHANGELOG.md`.
- [ ] Website/landing page (optional but useful for launch).

---

## P2 — after launch

- [ ] Auto-updates via Sparkle if not done.
- [ ] Localize the UI (the model supports 23 languages; the UI is English-only).
- [ ] Swift 6 strict concurrency migration.
- [ ] UI tests or snapshot tests for onboarding/settings.
- [ ] Opt-in crash reporting (privacy-preserving), only if you will act on it.
- [ ] Homebrew official cask.
- [ ] Press kit and launch posts.
- [ ] Monthly MAU check against the Emo free-tier limit.

---

## Release runbook

### 1. Preflight

```bash
cd /Users/sharath/Documents/Github/mac-emojis
make test
grep -rn "DEBUG-hx7" MacEmojis || true
xcodebuild -scheme MacEmojis -configuration Release -derivedDataPath build-release ARCHS=arm64 build
lipo -info build-release/Build/Products/Release/MacEmojis.app/Contents/MacOS/MacEmojis
```

### 2. Archive and export

```bash
xcodebuild -scheme MacEmojis -configuration Release \
  -archivePath build/MacEmojis.xcarchive archive ARCHS=arm64
```

`ExportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>developer-id</string>
  <key>signingStyle</key><string>automatic</string>
  <key>teamID</key><string>YOUR_TEAM_ID</string>
</dict>
</plist>
```

```bash
xcodebuild -exportArchive \
  -archivePath build/MacEmojis.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist

ditto -c -k --keepParent build/export/MacEmojis.app build/MacEmojis-0.1.0.zip
```

### 3. Notarize and staple the app

```bash
xcrun notarytool store-credentials "notary" \
  --apple-id "you@example.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "app-specific-password"

xcrun notarytool submit build/MacEmojis-0.1.0.zip \
  --keychain-profile "notary" --wait

xcrun stapler staple build/export/MacEmojis.app
xcrun stapler validate build/export/MacEmojis.app
spctl -a -vvv -t exec build/export/MacEmojis.app
```

### 4. DMG, notarize, staple

```bash
hdiutil create -volname "MacEmojis" \
  -srcfolder build/export/MacEmojis.app \
  -ov -format UDZO build/MacEmojis-0.1.0.dmg

xcrun notarytool submit build/MacEmojis-0.1.0.dmg \
  --keychain-profile "notary" --wait

xcrun stapler staple build/MacEmojis-0.1.0.dmg
xcrun stapler validate build/MacEmojis-0.1.0.dmg
spctl -a -vvv -t open --context context:primary-signature build/MacEmojis-0.1.0.dmg
```

### 5. Publish

```bash
shasum -a 256 build/MacEmojis-0.1.0.dmg > SHA256SUMS.txt
gh release create v0.1.0 \
  build/MacEmojis-0.1.0.dmg \
  build/MacEmojis-0.1.0.zip \
  SHA256SUMS.txt \
  --title "MacEmojis 0.1.0" \
  --notes-file docs/RELEASE_NOTES_0.1.0.md
```

---

## Decisions to make before P0 work

| Decision | Recommendation |
|---|---|
| License | MIT for simplicity, or Apache-2.0 if you want a patent grant |
| Distribution | Notarized DMG from GitHub Releases; skip the App Store |
| Architecture | Apple Silicon only for v0.1 |
| Version | `0.1.0` for a public beta, `1.0.0` if you consider it stable |
| Auto-update | Sparkle 2 if you can maintain an appcast; otherwise manual updates |
| Price | Free; the Emo license is free under 100k monthly devices |
| Confidence scores | Hide behind an advanced setting, or keep and explain them |

---

## Launch-day smoke test

- [ ] Fresh Mac/user account, no dev tools.
- [ ] Download DMG from the GitHub Release page.
- [ ] Drag to `/Applications`, open, no Gatekeeper block.
- [ ] Grant Accessibility, download model, complete onboarding.
- [ ] Type in TextEdit, Notes, Safari, Chrome, Slack; bubble appears; click inserts; undo works.
- [ ] `:cake` replaces the token.
- [ ] Secure field shows no bubble.
- [ ] Quit/relaunch; settings persist; login item works.
- [ ] Log out/in; Accessibility grant persists.
- [ ] Update to the next build; grant persists.
- [ ] Uninstall cleanly.
