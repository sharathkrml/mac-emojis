# MacEmojis — launch copy

Copy-paste drafts for the GitHub repo, profile, release, and launch posts. Edit the voice to match yours.

> **Source-only release:** the root `README.md` is the current public README. The longer README draft below is for the later signed-binary launch; skip the Install/Homebrew/DMG sections until binaries exist.
>
> Placeholders to replace before a binary launch: `YOUR_TEAM_ID`, `v0.1.0`, and the SHA-256.
>
> The README and privacy drafts assume the P0 fixes are done — especially removing typed text from the debug logs. That is now done in the repo.

---

## GitHub repo settings

**Description** (About field):

> A menu-bar Mac app that suggests emoji as you type — anywhere. On-device, private, open source. macOS 15+, Apple Silicon.

**Website:**

> https://github.com/sharathkrml/mac-emojis

**Topics:**

```
macos swift swiftui emoji emoji-picker menu-bar accessibility on-device coreml privacy productivity mac-app
```

**Social preview:** 1280×640 PNG. Left: app icon. Right: a bubble with 5 emoji chips over the line “i want a cake 🎂”. Headline: “The emoji you meant, right where you're typing.” Subhead: “On-device. Any app. macOS.” Use the app's near-black background and orange/blue gradient.

**Pin:** pin `mac-emojis` on your profile.

---

## GitHub profile

**Bio** (max 160 chars):

> Building small, private Mac apps. MacEmojis — emoji suggestions as you type, on-device. Swift/SwiftUI.

**Profile README blurb** (if you add one):

```markdown
### Hi, I'm Sharath 👋

I build small, private Mac apps.

**[MacEmojis](https://github.com/sharathkrml/mac-emojis)** — a menu-bar app that suggests emoji as you type, anywhere on macOS. On-device, no text leaves your Mac.
```

---

## README.md (public draft)

````markdown
# MacEmojis

**The emoji you meant, right where you're typing.**

MacEmojis is a menu-bar app for macOS that suggests emoji as you type — in any app. Type, pause, and a small thought bubble appears above the line with emoji that fit the moment. Click one to insert it.

Everything runs on your Mac. The 5 MB Emo model downloads once and works offline. No account, no ads, no analytics, and no typed text leaves your Mac.

<!-- TODO before publishing: add docs/demo.gif and replace this comment with:
<p align="center"><img src="docs/demo.gif" alt="MacEmojis suggestion bubble" width="640"></p>
-->

## Features

- **Works where you type.** Native apps, browsers, Electron apps — anywhere macOS exposes the focused text field.
- **A bubble, not a picker.** It appears above the sentence, never over your text, and stays out of the way until you pick.
- **Keyboard friendly.** Click the bubble, then use ←/→ and Enter. Esc dismisses it.
- **`:word` replace mode.** Type `:cake` and pick an emoji; the token is replaced, colon included.
- **Selection mode.** Highlight words and pause to rank emoji for the selection. Off by default.
- **Skin tone.** One preference, applied to every suggestion that supports tone.
- **Quiet by default.** Only suggestions scoring 0.2 or higher appear. If none clear the bar, no bubble shows.
- **Menu-bar native.** Toggle suggestions, open Settings, launch at login. No Dock icon.

## Install

1. Download the latest `MacEmojis-*.dmg` from [Releases](https://github.com/sharathkrml/mac-emojis/releases).
2. Drag **MacEmojis** to **Applications**. Move it before granting permission — macOS translocates apps run from Downloads.
3. Open MacEmojis from Applications.
4. Grant **Accessibility** when asked: System Settings → Privacy & Security → Accessibility.
5. Download the 5 MB emoji model in the onboarding window.
6. Type in any app, pause, and pick an emoji.

Homebrew (once a cask is published):

```bash
brew install --cask mac-emojis
```

## Privacy

MacEmojis reads the focused text field through macOS Accessibility so it can suggest emoji. That is the only reason it needs the permission.

- Typed text is processed in memory and is **never stored, logged, or sent**.
- Secure text fields and macOS secure input are skipped.
- Preferences stay in local `UserDefaults`.
- In web editors that keep their own text model, the app briefly uses the clipboard to paste the emoji, then restores your clipboard.
- The app makes two network requests:
  - **Model download** from Hugging Face, once, about 5 MB.
  - **Emo license check** to `events.desertant.com` when the model loads. It sends a random install ID, bundle ID, model/SDK version, and platform. It does **not** send typed text.
- No analytics, ads, accounts, or crash reporting.

Full policy: [PRIVACY.md](PRIVACY.md).

## Requirements

- macOS 15 (Sequoia) or later.
- Apple Silicon (M1 or later). Current builds are arm64 only.
- Accessibility permission.
- About 5 MB for the model, plus the app.

## How it works

MacEmojis polls the focused text field through the Accessibility API. It passes the text after the last sentence terminator (capped at 150 characters) to [Emo](https://desertant.com/models/emo/), a small on-device Core ML model that ranks emoji for short phrases. Suggestions below the confidence floor are dropped. The bubble is a non-activating panel; clicking a chip inserts through Accessibility, with a paste fallback for web editors.

See [GLOSSARY.md](GLOSSARY.md) for the terms and [docs/adr](docs/adr) for the design decisions.

## Build from source

Requirements: macOS 15+, Xcode 26+, [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
make run     # generate project, build, relaunch
make test    # run the unit tests
make clean   # remove build products
```

Manual build:

```bash
xcodegen generate
xcodebuild -scheme MacEmojis -configuration Debug \
  -derivedDataPath build \
  -destination 'platform=macOS,arch=arm64' build
open build/Build/Products/Debug/MacEmojis.app
```

The project is configured for the author's Apple Development team. Use your own team in `project.yml` (or automatic signing) and grant Accessibility once for your build.

Release build (Apple Silicon):

```bash
xcodebuild -scheme MacEmojis -configuration Release \
  -derivedDataPath build-release ARCHS=arm64 build
```

Tests: 27 unit tests covering sentence slicing, bubble placement, and Accessibility frame alignment.

## Troubleshooting

**No bubble appears.**
Check Accessibility is granted, the field is not secure, and the app draws a real text field (canvas editors like Google Docs and Figma expose no text). The default pause is 0.8 s; try lowering it in Settings.

**The bubble appears in the wrong place.**
Some apps report unusual Accessibility frames. Please open an issue with the app name, macOS version, and a screenshot.

**Accessibility stopped working after a rebuild.**
Remove MacEmojis from the Accessibility list with “−”, then add the new build. Grants are tied to the signing identity.

**The model download fails.**
Check your network and retry from Settings. The model is cached at `~/Library/Caches/desert-ant-models`.

**Uninstall.**
Quit MacEmojis, delete it from Applications, remove it from Accessibility, then optionally delete the cache folders and preferences:

```bash
rm -rf ~/Library/Caches/desert-ant-models
rm -rf ~/Library/Caches/com.sharath.MacEmojis
defaults delete com.sharath.MacEmojis
```

## Contributing

Issues and pull requests are welcome. Run `make test` before sending a PR. Keep changes small, include a test when the logic is non-trivial, and do not add telemetry or network calls without discussing them first. See [CONTRIBUTING.md](CONTRIBUTING.md).

## Credits

- **Emo** by [Desert Ant Labs](https://desertant.com/) — the on-device emoji model. Required attribution: **Powered by [Desert Ant Labs](https://desertant.com/) 🐜**.
- Built with SwiftUI and AppKit.
- Emoji artwork is rendered by macOS.

## License

MacEmojis is open source under the [MIT License](LICENSE) (replace if you choose another license).

The Emo model and SDK are licensed separately by Desert Ant Labs under the [Desert Ant Labs Source-Available License](https://license.desertant.com/). They are free below 100,000 monthly active devices per platform, per model. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
````

---

## PRIVACY.md (draft)

```markdown
# Privacy Policy

**Effective date:** 2026-11-21

MacEmojis is a menu-bar app that suggests emoji as you type. This policy explains what the app accesses, stores, and sends.

## The short version

- MacEmojis does **not** collect, store, or transmit the text you type.
- It reads the focused text field through macOS Accessibility only to generate suggestions.
- There are no accounts, ads, analytics, or crash reports.
- Two network requests exist: the one-time model download and the Emo license check.

## What the app accesses

**Accessibility.** MacEmojis reads the focused text field and its selection so it can suggest emoji. It also inserts the emoji you pick. The app skips fields with the `AXSecureTextField` subrole and does nothing while macOS secure input is active.

**Clipboard.** In web editors that keep their own text model (for example X, Gmail, and Slack), the app briefly writes the chosen emoji to the clipboard, pastes it, then restores the previous clipboard contents. Clipboard managers on your Mac may observe this temporary value.

## What is stored on your Mac

- Preferences (enabled state, pause, suggestion count, skin tone, onboarding state) in `UserDefaults` under `com.sharath.MacEmojis`.
- The Emo model in `~/Library/Caches/desert-ant-models`.
- A random install ID used by the Emo license check.

Typed text is not written to disk or to logs.

## Network requests

| Destination | When | What is sent |
|---|---|---|
| `huggingface.co` | First model download, or after clearing the cache | Standard HTTPS request for the public Emo model files. No typed text. |
| `events.desertant.com` | When the Emo model loads | Random install ID, bundle ID, model name/version, SDK version, and platform. No typed text. |

Like any network request, these reveal your IP address to the destination.

## Third parties

- **Hugging Face** hosts the Emo model files. See Hugging Face's privacy policy.
- **Desert Ant Labs** provides the Emo model and SDK and receives the license check described above. See <https://desertant.com/>.

## Analytics and tracking

MacEmojis has no analytics, advertising, tracking pixels, or third-party crash reporting. It does not track you across apps or websites.

## Children

MacEmojis is a general-purpose productivity app and does not knowingly collect personal information from anyone.

## Changes

If this policy changes, the new version will be published in this repository with a new effective date.

## Contact

Open an issue at <https://github.com/sharathkrml/mac-emojis/issues> or email the maintainer.
```

---

## SECURITY.md (draft)

```markdown
# Security Policy

## Reporting a vulnerability

Please report security issues privately through GitHub's **Report a vulnerability** button under the repository's Security tab. Do not open a public issue.

Include:

- macOS version and MacEmojis version
- The app you were typing in, if relevant
- Steps to reproduce
- What you expected and what happened

You can expect an acknowledgement within a few days. Please give me a reasonable window to fix the issue before disclosing it publicly.

## Scope

MacEmojis runs locally and reads text through macOS Accessibility. Issues involving text exposure, unintended network requests, clipboard handling, or signing/updates are in scope.
```

---

## CONTRIBUTING.md (draft)

```markdown
# Contributing

Thanks for helping. MacEmojis is a small SwiftUI/AppKit app; keep changes focused.

## Build

```bash
brew install xcodegen
make run
make test
```

The project is generated by XcodeGen from `project.yml`; do not edit `MacEmojis.xcodeproj` by hand.

The committed project is configured for the author's Apple Development team. Use your own team in `project.yml`, or switch to automatic signing. Accessibility grants are tied to the signing identity, so a rebuild with a different team needs a fresh grant.

## Pull requests

- Run `make test`.
- Add a test for non-trivial logic (sentence slicing, placement, insertion).
- Keep the privacy promise: no telemetry, no new network calls, no text logging.
- Describe the app and macOS version you tested with.
- Keep the diff small; separate refactors from behavior changes.

## Code style

Follow the surrounding Swift style. Prefer small types and explicit names. Comments explain *why*, not *what*.
```

---

## CHANGELOG.md (draft)

```markdown
# Changelog

## 0.1.0 — 2026-11-21

First public release.

- Menu-bar emoji suggestions in any app with a focused text field.
- Confidence floor: suggestions below 0.2 are hidden.
- `:word` replace mode.
- Selection suggestions (off by default).
- Skin tone preference.
- On-device Emo model, downloaded once.
- Onboarding, Settings, launch at login.
- Notarized Apple Silicon build for macOS 15+.
```

---

## Release notes — v0.1.0

```markdown
## MacEmojis 0.1.0

First public release.

### What it does

Type in any app and pause. A thought bubble appears above the line with emoji that fit the moment. Click one to insert it, or click the bubble and use ←/→ + Enter. Type `:cake` to rank emoji for a word and replace the token. Select words and pause to rank emoji for the selection (off by default).

Everything runs on-device. The 5 MB Emo model downloads once; no typed text leaves your Mac.

### Requirements

- macOS 15 (Sequoia) or later
- Apple Silicon (M1 or later)
- Accessibility permission

### Install

1. Download `MacEmojis-0.1.0.dmg` below.
2. Drag MacEmojis to Applications.
3. Open it, grant Accessibility, and download the model.

### Known issues

- Canvas-based editors (Google Docs, Figma, some Java apps) expose no text, so the bubble cannot follow the caret.
- Web editors use a paste fallback so their own undo and Backspace keep working.
- Current builds are Apple Silicon only.

### Verification

- Signed with a Developer ID certificate and notarized by Apple.
- SHA-256: `REPLACE_WITH_SHA256`

If macOS blocks the app, make sure you downloaded it from this release and that it is in Applications.
```

---

## Homebrew cask (once notarized)

```ruby
cask "mac-emojis" do
  version "0.1.0"
  sha256 "REPLACE_WITH_SHA256"

  url "https://github.com/sharathkrml/mac-emojis/releases/download/v#{version}/MacEmojis-#{version}.dmg"
  name "MacEmojis"
  desc "On-device emoji suggestions as you type, anywhere on macOS"
  homepage "https://github.com/sharathkrml/mac-emojis"

  depends_on macos: ">= :sequoia"
  depends_on arch: :arm64

  app "MacEmojis.app"
end
```

---

## Launch posts

### Show HN

**Title:** Show HN: MacEmojis – on-device emoji suggestions while you type on macOS

**Body:**

> I built a menu-bar app that watches the focused text field, and when you pause, shows a small bubble of emoji that fit the sentence. Click one to insert it. Type `:cake` to replace a token. It works in native apps, browsers, and Electron apps.
>
> The model is Emo, a ~5 MB on-device Core ML model from Desert Ant Labs. Text never leaves the Mac; there is no account, analytics, or telemetry. The app needs Accessibility permission to read the field and insert the emoji, which is the main trust hurdle.
>
> Current build is macOS 15+, Apple Silicon. It is free and open source. I would love feedback on the bubble placement, which apps it fails in, and whether the confidence scores are useful or just noise.
>
> Repo: https://github.com/sharathkrml/mac-emojis

### Reddit — r/macapps

**Title:** MacEmojis: a menu-bar app that suggests emoji as you type, anywhere (on-device, free)

**Body:**

> I made a small Mac app: type in any app, pause, and a thought bubble appears above the line with emoji that fit the sentence. Click one to insert. `:cake` works too. Selection suggestions are optional.
>
> It runs entirely on-device using a 5 MB Core ML model. No account, no analytics, no text leaves the Mac. It does need Accessibility permission to read the focused field and insert the emoji; secure fields are skipped.
>
> macOS 15+, Apple Silicon for now. Free and open source. Feedback welcome, especially which apps it does not work in.

### X / Bluesky

> I built MacEmojis: type anywhere on macOS, pause, and a little bubble suggests emoji for the sentence. Click to insert. `:cake` replaces the token.
>
> On-device. No account. No analytics. No text leaves the Mac.
>
> Free and open source. macOS 15+, Apple Silicon.
>
> https://github.com/sharathkrml/mac-emojis

### Product Hunt

**Tagline:** Emoji suggestions as you type, anywhere on macOS.

**Description:**

> MacEmojis is a menu-bar app that suggests emoji for whatever you are typing. Pause and a thought bubble appears above the line; click an emoji to insert it. Type `:cake` to replace a token, or select words to rank emoji for the selection. Everything runs on-device with a 5 MB model. No account, no analytics, no text leaves your Mac. Free and open source.

### LinkedIn

> Desert Ant Labs is a hyper-focused lab building AI models that run on your own device. One of them, Emo, reads a line of text and tells you which emoji fit the moment.
>
> I used it to build MacEmojis.
>
> I type "i want a cake". I pause. A little thought bubble appears above the line: 🎂 🍰 🥳. I click one and it's in the sentence. That's the whole interaction.
>
> Why it's nice:
>
> • The model is 5 MB and runs offline. Your text never leaves the Mac.
> • No picker to scroll, and no account, ads or analytics.
> • Works anywhere macOS exposes a text field — native apps, Slack, Gmail, X.
> • Type :cake and it replaces the token. Highlight a word and pause to rank emoji for it.
>
> It's free and open source (MIT). macOS 15+ on Apple Silicon only, built from source for now.
>
> Repo is in the comments 👇
>
> I'd love feedback: which apps does it fail in, and does the bubble sit in the right place?

### X — single post

> I type "i want a cake", pause, and a bubble offers 🎂 🍰 🥳. One click and it's in.
>
> MacEmojis: emoji suggestions as you type, anywhere on macOS. Powered by Emo, a 5 MB on-device model from Desert Ant Labs.
>
> Free & open source ↓
> github.com/sharathkrml/mac-emojis

### X — 3-post thread

1/
> I type "i want a cake", pause, and a bubble offers 🎂 🍰 🥳.
>
> One click and it's in. No picker.
>
> Watch: [screen recording]

2/
> The model is Emo, from Desert Ant Labs: 5 MB, runs on the Mac, ranks emoji for the last sentence you typed. No API call, no text uploaded.
>
> The app is MacEmojis. Menu bar, no Dock icon, works anywhere macOS has a text field.

3/
> Free and open source (MIT). macOS 15+, Apple Silicon, build from source today.
>
> github.com/sharathkrml/mac-emojis
>
> Tell me which app the bubble fails in — that's the feedback I want most.

### Instagram Reel — ~40s

Voiceover + burned-in captions. Screen recording of the real app, cropped to 9:16.

```text
0:00–0:03  HOOK
VO:   "Watch what happens when I pause after this sentence."
SHOT: Notes, typing "i want a cake"
TEXT: wait for it 👀

0:03–0:08  PAYOFF
VO:   "A bubble shows up with the emoji I actually meant. One click."
SHOT: bubble appears (🎂 🍰 🥳), click 🎂, sentence completes
TEXT: no picker. no scrolling.

0:08–0:13  WHO / WHAT
VO:   "This is MacEmojis, a tiny app I built on top of Emo — a 5 MB AI model
       from Desert Ant Labs that runs fully on your device."
SHOT: app icon / menu bar / model "Ready" in onboarding
TEXT: 5 MB. on-device.

0:13–0:22  HOW
VO:   "It reads the last sentence you typed and ranks the emoji that fit.
       Nothing leaves the laptop. No account, no analytics."
SHOT: type in Slack, then Gmail, bubble appears in each
TEXT: your text stays on your Mac

0:22–0:30  EXTRA
VO:   "Type colon cake and it replaces the word. Highlight something and
       pause to rank emoji for the selection."
SHOT: :cake replace, then select a word and pause
TEXT: works in almost any app

0:30–0:38  CTA
VO:   "It's free and open source. Repo is in the caption — build it,
       and tell me which app it breaks in."
SHOT: end card
TEXT: MacEmojis · free & open source · link in bio
```

**Hook alternates:**

- "I stopped picking emoji. My Mac does it now."
- "You type. You pause. The emoji is already there."
- "POV: your Mac knows which emoji you meant."

**Caption:**

> POV: you never open the emoji picker again.
>
> MacEmojis suggests the emoji you meant as you type — anywhere on your Mac. Built on Emo, a 5 MB on-device model from Desert Ant Labs. Your text never leaves the laptop.
>
> Free and open source. Link in bio → github.com/sharathkrml/mac-emojis
>
> macOS 15+, Apple Silicon. Build from source for now.
>
> #buildinpublic #macos #swiftui #ondeviceai #opensource #indiedev #emoji

**Notes:**

- Instagram links in captions and comments are not clickable. Use "link in bio" while this is fresh, and keep the repo pinned in your bio.
- Record at 2x and crop. Turn on Do Not Disturb, close personal tabs, and use fake text only.
- Burn in captions; most viewers watch muted.
- Keep each shot under 3s. The bubble must be visible for at least 2s.
- Post the same reel as a native video on LinkedIn too, with the repo in the first comment.

---

## Screenshot / GIF shot list

1. **Hero GIF:** TextEdit or Notes; type “i want a cake”, pause, bubble appears, click 🎂, text becomes “i want a cake 🎂”.
2. **Replace mode:** type `:heart`, bubble appears, pick ❤️, token replaced.
3. **Settings:** suggestions block, skin tone, pause slider.
4. **Onboarding:** welcome screen with the app mark.
5. **Privacy:** the permission block showing “Granted” and the model “Ready”.
6. **Social preview:** icon + bubble + tagline, 1280×640.

Keep GIFs under ~8 MB and record at 2x, cropped to the relevant window. Do not show real personal text, email addresses, or notifications.
