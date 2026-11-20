# MacEmojis

A menu-bar Mac app that suggests emoji for whatever you are typing, anywhere, using the on-device [Emo](https://desertant.com/models/emo/) model.

- Type in any app and pause: a thought bubble of emoji appears above the sentence, never covering the text, and animates in. Click an emoji to insert it at the caret; or click the bubble itself, then ←/→ + Enter.
- Type `:cake` (a colon token): the bubble ranks suggestions for that word, and picking one replaces the token, colon included.
- Select some words and pause (off by default, Settings → Suggestions): the bubble ranks emoji for the selection, and picking one appends it at the end of the selected text.

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

On first launch a four-step onboarding panel opens: welcome, Accessibility plus the model download, a live emoji demo, and bubble preferences. Afterwards the menu-bar face toggles the app and its menu opens Settings.

Tests:

```bash
xcodebuild -scheme MacEmojis -derivedDataPath build test
```

## Notes

- Needs macOS 15+ (Emo's Core ML model) and Xcode 26+.
- Accessibility is the only permission used, and it is granted once to MacEmojis — not to each app it reads.
- Signed with an Apple Development certificate (team `83JSBLYT7Z`) so the Accessibility grant survives rebuilds. On another machine, use your own team in [project.yml](./project.yml) and grant once.
- Works anywhere macOS exposes the focused text field; Chromium/Electron apps are switched on automatically. Apps that draw their own editor (Google Docs canvas, Figma, some Java apps) expose no text, so the caret cannot be followed there.
- Picking an emoji in a web editor (X/Twitter, Gmail, Slack) uses a paste so the site's own undo and Backspace keep working.
- The app is signed with an Apple Development certificate for local development. Rebuilding on the same machine keeps the grant; rebuilding with a different team does not.
- The Emo SDK is source-available and free below 100k monthly devices.
