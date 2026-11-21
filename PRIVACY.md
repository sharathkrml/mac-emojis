# Privacy Policy

**Effective date:** 2026-11-21

MacEmojis is a menu-bar app that suggests emoji as you type. This policy explains what the app accesses, stores, and sends. It applies to the app built from this repository at version 0.1.0.

## The short version

- MacEmojis does **not** collect, store, log, or transmit the text you type.
- It reads the focused text field through macOS Accessibility only to generate suggestions.
- There are no accounts, ads, analytics, or crash reports.
- The app talks to two network services: the one-time model download and the Emo license check.

## What the app accesses

**Accessibility.** MacEmojis reads the focused text field and its selection so it can suggest emoji. It also inserts the emoji you pick. The app skips fields with the `AXSecureTextField` subrole and does nothing while macOS secure input is active.

**Clipboard.** In web editors that keep their own text model (for example X, Gmail, and Slack), the app briefly writes the chosen emoji to the clipboard, pastes it, then restores the previous clipboard contents. Clipboard managers on your Mac may observe this temporary value.

## What is stored on your Mac

- Preferences (enabled state, pause, suggestion count, skin tone, onboarding state) in `UserDefaults` under `com.sharath.MacEmojis`.
- The Emo model in `~/Library/Caches/desert-ant-models`.
- A random install ID used by the Emo license check, stored in `UserDefaults`.

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

Open an issue at <https://github.com/sharathkrml/mac-emojis/issues> or email <sharathkrml@gmail.com>.
