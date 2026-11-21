# Glossary

**Sentence Suggest** — The mode where pausing mid-sentence in a focused text field shows a bubble of emoji that fit the sentence so far; picking one inserts it at the caret. The emoji is appended to the sentence, not replacing any text.

**Replace Mode** — The mode triggered by a trailing `:word` token (e.g. `:heart`). Picking an emoji deletes the token, colon included, and puts the emoji in its place. Ranking reads only the word after the colon.

**Selection Suggest** — The mode where highlighting words and pausing shows a bubble ranked from the selected text. Picking appends the emoji at the end of the selection; the words are kept. Off by default, because selections are made for many reasons.

**Suggestion Bubble** — The floating thought bubble of up to 8 emoji candidates (5 by default), anchored above the typed line with a tail pointing at the caret. If the caret is below the first line of a multi-line field it rises above the whole field instead, so no text is covered. It appears without stealing focus; clicking an emoji inserts it, while clicking the bubble itself engages it for ←/→ and Enter.

**Pause Debounce** — The quiet period after the last text change (default 0.8 s) that must pass before the Suggestion Bubble appears. Fully configurable in Settings.

**Confidence Floor** — Emo scores every candidate from 0 to 1. Suggestions below 0.2 (`EmoService.minConfidence`) are dropped, and if nothing clears the floor no bubble appears, so plain or ambiguous text stays quiet.

**Sentence Slice** — The text handed to Emo: everything after the last `.`, `?`, `!` or newline up to the caret, capped at 150 characters. Emo is tuned for short intent text, not whole drafts.

**Focused Field** — The text input element the user is typing into, read through macOS Accessibility. Fields with the `AXSecureTextField` subrole are never read.

**Skin Tone** — One global preference (base through dark) applied by Emo to every suggested emoji that supports tone variants.
