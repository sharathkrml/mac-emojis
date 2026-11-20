# Glossary

**Sentence Suggest** — The mode where pausing mid-sentence in a focused text field shows a bubble of emoji that fit the sentence so far; picking one inserts it at the caret. The emoji is appended to the sentence, not replacing any text.

**Replace Mode** — The mode triggered by a trailing `:word` token (e.g. `:heart`). Picking an emoji deletes the token, colon included, and puts the emoji in its place. Ranking reads only the word after the colon.

**Suggestion Bubble** — The floating, caret-anchored panel of up to 8 emoji candidates (5 by default). It appears without stealing focus; the first click engages it, then ←/→ move the highlight and Enter — or a second click — chooses.

**Pause Debounce** — The quiet period after the last text change (default 0.8 s) that must pass before the Suggestion Bubble appears. Fully configurable in Settings.

**Sentence Slice** — The text handed to Emo: everything after the last `.`, `?`, `!` or newline up to the caret, capped at 150 characters. Emo is tuned for short intent text, not whole drafts.

**Focused Field** — The text input element the user is typing into, read through macOS Accessibility. Fields with the `AXSecureTextField` subrole are never read.

**Skin Tone** — One global preference (base through dark) applied by Emo to every suggested emoji that supports tone variants.
