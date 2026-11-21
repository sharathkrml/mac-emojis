# MacEmojis

[![CI](https://github.com/sharathkrml/mac-emojis/actions/workflows/ci.yml/badge.svg)](https://github.com/sharathkrml/mac-emojis/actions/workflows/ci.yml)

**The emoji you meant, right where you're typing.**

MacEmojis is a menu-bar app for macOS that suggests emoji as you type — in any app. Type, pause, and a small thought bubble appears above the line with emoji that fit the moment. Click one to insert it.

> **Status: source-code release (0.1.0).** There is no signed or notarized binary yet. Build from source below.

Everything runs on your Mac. The 5 MB Emo model downloads once and works offline. No account, no ads, no analytics, and no typed text leaves your Mac.

## Features

- **Works where you type.** Native apps, browsers, and Electron apps — anywhere macOS exposes the focused text field.
- **A bubble, not a picker.** It appears above the sentence, never over your text, and stays out of the way until you pick.
- **Keyboard friendly.** Click the bubble, then use ←/→ and Enter. Esc dismisses it.
- **`:word` replace mode.** Type `:cake` and pick an emoji; the token is replaced, colon included.
- **Selection mode.** Highlight words and pause to rank emoji for the selection. Off by default.
- **Skin tone.** One preference, applied to every suggestion that supports tone.
- **Quiet by default.** Only suggestions scoring 0.2 or higher appear. If none clear the bar, no bubble shows.
- **Menu-bar native.** Toggle suggestions, open Settings, launch at login. No Dock icon.

## Build from source

Requirements:

- macOS 15 (Sequoia) or later.
- Apple Silicon (M1 or later). The Emo SDK's Core AI path does not compile for x86_64.
- Xcode 26 or later (tested with Xcode 27.2).
- [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
make run     # generate project, build, relaunch
make test    # run the unit tests
make clean   # remove build products
```

Or manually:

```bash
xcodegen generate
xcodebuild -scheme MacEmojis -configuration Debug \
  -derivedDataPath build \
  -destination 'platform=macOS,arch=arm64' build
open build/Build/Products/Debug/MacEmojis.app
```

On first launch, a four-step onboarding panel opens: welcome, Accessibility plus the model download, a live emoji demo, and bubble preferences. The menu-bar face toggles the app; its menu opens Settings and About.

### Signing

The project builds with ad-hoc signing by default so anyone can compile it. An ad-hoc signature changes on every rebuild, which may reset the Accessibility grant. For a stable grant, set your own Apple Development team in Xcode or pass it to `xcodebuild`:

```bash
xcodebuild -scheme MacEmojis -configuration Debug \
  -derivedDataPath build \
  -destination 'platform=macOS,arch=arm64' \
  DEVELOPMENT_TEAM=YOUR_TEAM_ID \
  CODE_SIGN_IDENTITY="Apple Development" build
```

### Release build

```bash
make release
```

`make release` passes `ARCHS=arm64` explicitly. Without it, Xcode also builds the Emo package for x86_64, where its Core AI sources do not compile. Release builds are Apple Silicon only until that is fixed upstream.

The Emo SDK is pinned to `4.3.0`.

## Privacy

MacEmojis reads the focused text field through macOS Accessibility so it can suggest emoji. That is the only reason it needs the permission.

- Typed text is processed in memory and is never stored, logged, or sent.
- Secure text fields and macOS secure input are skipped.
- Preferences stay in local `UserDefaults`.
- In web editors that keep their own text model (X/Twitter, Gmail, Slack), the app briefly uses the clipboard to paste the emoji, then restores your clipboard.
- The app talks to two network services:
  - **Model download** from Hugging Face, once, about 5 MB.
  - **Emo license check** to `events.desertant.com` when the model loads. It sends a random install ID, bundle ID, model/SDK version, and platform. It does **not** send typed text.
- No analytics, ads, accounts, or crash reporting.

Read the full [Privacy Policy](PRIVACY.md).

## How it works

MacEmojis polls the focused text field through the Accessibility API. It passes the text after the last sentence terminator (capped at 150 characters) to [Emo](https://desertant.com/models/emo/), a small on-device Core ML model that ranks emoji for short phrases. Suggestions below the confidence floor are dropped. The bubble is a non-activating panel; clicking a chip inserts through Accessibility, with a paste fallback for web editors.

See [GLOSSARY.md](GLOSSARY.md) for the terms and [docs/adr](docs/adr) for design decisions.

## Known limitations

- Canvas-based editors (Google Docs, Figma, some Java apps) expose no text, so the bubble cannot follow the caret.
- Web editors use a paste fallback so their own undo and Backspace keep working.
- Some apps report unusual Accessibility frames; the bubble may land in the wrong place.
- The UI is English-only. The Emo model supports 23 languages.
- Current builds are Apple Silicon only.
- No signed binary is published yet.

## Troubleshooting

**No bubble appears.**
Check Accessibility is granted, the field is not secure, and the app draws a real text field. The default pause is 0.8 s; try lowering it in Settings.

**The bubble appears in the wrong place.**
Open an issue with the app name, macOS version, and a screenshot.

**Accessibility stopped working after a rebuild.**
Remove MacEmojis from the Accessibility list with “−”, then add the new build. Grants are tied to the signing identity. Use a stable team to avoid this.

**The model download fails.**
Check your network and retry from Settings. The model is cached at `~/Library/Caches/desert-ant-models`.

**Uninstall.**
Quit MacEmojis, delete it from Applications, remove it from Accessibility, then optionally delete the cache and preferences:

```bash
rm -rf ~/Library/Caches/desert-ant-models
rm -rf ~/Library/Caches/com.sharath.MacEmojis
defaults delete com.sharath.MacEmojis
```

## Contributing

Issues and pull requests are welcome. Run `make test` before sending a PR. Keep changes small, include a test when the logic is non-trivial, and do not add telemetry or network calls without discussing them first. See [CONTRIBUTING.md](CONTRIBUTING.md).

Security issues: please report them privately — see [SECURITY.md](SECURITY.md).

## Credits

- **Emo** by [Desert Ant Labs](https://desertant.com/) — the on-device emoji model. Required attribution: **Powered by [Desert Ant Labs](https://desertant.com/) 🐜**.
- Built with SwiftUI and AppKit.
- Emoji artwork is rendered by macOS.

## License

MacEmojis is open source under the [MIT License](LICENSE).

The Emo model and SDK are licensed separately by Desert Ant Labs under the [Desert Ant Labs Source-Available License](https://license.desertant.com/). They are free below 100,000 monthly active devices per platform, per model. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
