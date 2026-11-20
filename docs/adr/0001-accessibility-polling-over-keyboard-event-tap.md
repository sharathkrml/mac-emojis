# 0001 — Read typing through Accessibility polling, not a keyboard event tap

## Status

Accepted.

## Context

MacEmojis must know what the user is typing in *any* app, then react when they pause. There are two ways on macOS:

1. **Global keyboard event tap** (`CGEventTap`): sees every keypress; requires the Input Monitoring permission and looks like a keylogger to users and to TCC.
2. **Accessibility (AX) polling**: read the focused text element's value and selection roughly every 200 ms; requires only the Accessibility permission, and reads the text field's content rather than raw keystrokes.

The interaction already waits for a pause of ~0.8 s before suggesting, and Emo takes <2 ms per suggestion, so per-keystroke precision buys nothing. Picking a suggestion is click-driven (one click on an emoji inserts it; clicking the bubble's rim engages it for ←/→ + Enter), so no key capture is needed for navigation either.

## Decision

Poll the focused AXUIElement every 200 ms and derive text changes, the sentence slice, and the colon token from its value and selected range. Do not install a keyboard event tap, and do not request Input Monitoring.

Skip fields whose subrole is `AXSecureTextField`; also skip the Terminal app in v1. When the app itself is focused (onboarding test field), the same code path works without Accessibility trust, which makes the test field a useful pre-permission check.

## Consequences

- One permission instead of two; no keylogging surface.
- Some apps (a few Electron/web targets, Java apps) expose no AX value for their text fields. The suggestion bubble simply won't appear there; this is a per-app limitation that could only be fixed by a keyboard tap, which we rejected.
- Polling costs a few wake-ups per second and keeps a 0.8 s debounce honest; the model call itself is negligible.
- Password fields are protected by AX, but a secure field that *does* expose text would still be skipped by subrole; we add a global `IsSecureEventInputEnabled()` check as a second net where available.
