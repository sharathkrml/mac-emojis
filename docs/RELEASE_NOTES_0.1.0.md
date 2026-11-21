# MacEmojis 0.1.0 — source release

First public source release. There is **no signed or notarized binary yet**; this release is the code.

## What it does

Type in any app and pause. A thought bubble appears above the line with emoji that fit the moment. Click one to insert it, or click the bubble and use ←/→ + Enter. Type `:cake` to rank emoji for a word and replace the token. Select words and pause to rank emoji for the selection (off by default).

Everything runs on-device. The 5 MB Emo model downloads once; no typed text leaves your Mac.

## Requirements

- macOS 15 (Sequoia) or later
- Apple Silicon (M1 or later)
- Xcode 26 or later and XcodeGen to build
- Accessibility permission at runtime

## Build

```bash
brew install xcodegen
make run
make test
```

## Notes

- The Emo SDK is pinned to 4.3.0 and is Apple Silicon only for now.
- The app builds with ad-hoc signing by default. Set your own Apple Development team for a stable Accessibility grant.
- The UI is English-only; the model supports 23 languages.
- Canvas-based editors (Google Docs, Figma, some Java apps) expose no text and are not supported.

## License

MacEmojis is MIT licensed. Emo is source-available from Desert Ant Labs; see `THIRD_PARTY_NOTICES.md`.
