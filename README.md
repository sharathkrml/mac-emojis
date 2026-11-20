# MacEmojis

A menu-bar Mac app that suggests emoji for whatever you are typing, anywhere, using the on-device [Emo](https://desertant.com/models/emo/) model.

- Type in any app and pause: a bubble of emoji appears above the caret. Click it once to engage, then ←/→ + Enter (or click an emoji) inserts it at the caret.
- Type `:cake` (a colon token): the bubble ranks suggestions for that word, and picking one replaces the token, colon included.

Everything runs on-device. Emo downloads once (5 MB) from Hugging Face and caches; no text ever leaves the Mac.

## Build and run

```bash
make run     # generate project, build, relaunch the app
make test    # run the unit tests
make clean   # remove build products
```

Or manually:

```bash
xcodegen generate
xcodebuild -scheme MacEmojis -configuration Debug -derivedDataPath build build
open build/Build/Products/Debug/MacEmojis.app
```

On first launch the window opens: grant Accessibility, download the model, and try the built-in test field. The menu-bar face icon toggles the app and opens Settings.

Tests:

```bash
xcodebuild -scheme MacEmojis -derivedDataPath build test
```

## Notes

- Needs macOS 15+ (Emo's Core ML model) and Xcode 26+.
- Accessibility is the only permission used; there is no keyboard event tap and no Input Monitoring.
- Signed with an Apple Development certificate (team `83JSBLYT7Z`) so the Accessibility grant survives rebuilds. On another machine, use your own team in [project.yml](./project.yml) and grant once.
- Text fields in a few apps (some Electron/Java apps) do not expose their text through Accessibility, so the bubble will not appear there.
- The app is signed with an Apple Development certificate for local development. Rebuilding on the same machine keeps the grant; rebuilding with a different team does not.
- The Emo SDK is source-available and free below 100k monthly devices.
