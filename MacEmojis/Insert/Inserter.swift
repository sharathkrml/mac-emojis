import AppKit
import ApplicationServices

@MainActor
enum Inserter {
    static func insert(_ emoji: String, context: SuggestionContext, snapshot: FieldSnapshot) {
        let text = snapshot.value as NSString
        let range: NSRange
        let insertion: String

        switch context {
        case .replace(_, let tokenRange):
            range = tokenRange
            insertion = emoji
        case .sentence(_, let caret):
            range = NSRange(location: caret, length: 0)
            let before = caret > 0
                ? text.substring(with: NSRange(location: caret - 1, length: 1)).first
                : nil
            insertion = composedText(emoji: emoji, caret: caret, charBefore: before)
        case .selection(_, let selRange):
            range = NSRange(location: NSMaxRange(selRange), length: 0)
            let end = range.location
            let before = end > 0
                ? text.substring(with: NSRange(location: end - 1, length: 1)).first
                : nil
            insertion = composedText(emoji: emoji, caret: end, charBefore: before)
        }

        if snapshot.pid == ProcessInfo.processInfo.processIdentifier {
            NSApp.activate(ignoringOtherApps: true)
        } else if let app = NSRunningApplication(processIdentifier: snapshot.pid) {
            _ = app.activate(options: [])
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)

            if snapshot.pid == ProcessInfo.processInfo.processIdentifier,
               let window = NSApp.windows.first(where: { $0.isVisible && $0.canBecomeKey }) {
                window.makeKeyAndOrderFront(nil)
            }

            AXUIElementSetAttributeValue(snapshot.element, kAXFocusedAttribute as CFString, kCFBooleanTrue)
            try? await Task.sleep(nanoseconds: 40_000_000)

            // Web editors (Twitter/Draft.js, Gmail, Slack) keep their own text model.
            // Mutating AXSelectedText changes the DOM but not the model, which leaves
            // ghost text and a dead Backspace. A real paste goes through the editor.
            if snapshot.isWebContent {
                fallbackPaste(range: range, text: insertion, into: snapshot.element)
                return
            }

            if AXField.apply(range, text: insertion, to: snapshot.element) {
                return
            }
            if AXField.replaceValue(range, with: insertion, in: snapshot.element) {
                return
            }
            fallbackPaste(range: range, text: insertion, into: snapshot.element)
        }
    }

    /// One space before the emoji when the caret follows a non-space, so text reads `cake 🎂`.
    nonisolated static func composedText(emoji: String, caret: Int, charBefore: Character?) -> String {
        guard caret > 0, let charBefore, !charBefore.isWhitespace else { return emoji }
        return " " + emoji
    }

    private static func fallbackPaste(range: NSRange, text: String, into element: AXUIElement) {
        AXField.select(range, in: element)

        // NSPasteboardItem is not NSCopying; snapshot it by its data, or `copy()`
        // raises an exception that aborts the insertion before Cmd+V is posted.
        let pasteboard = NSPasteboard.general
        let saved: [NSPasteboardItem] = pasteboard.pasteboardItems?.map { item -> NSPasteboardItem in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    copy.setData(data, forType: type)
                }
            }
            return copy
        } ?? []
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        let ownChangeCount = pasteboard.changeCount

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 120_000_000)
            postCommandV()
            try? await Task.sleep(nanoseconds: 400_000_000)
            // Restore only if nothing copied after us; otherwise we would clobber
            // the user's newer clipboard contents.
            guard pasteboard.changeCount == ownChangeCount else { return }
            pasteboard.clearContents()
            if !saved.isEmpty { pasteboard.writeObjects(saved) }
        }
    }

    private static func postCommandV() {
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return }
        for isDown in [true, false] {
            let event = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: isDown)
            event?.flags = .maskCommand
            event?.post(tap: .cghidEventTap)
        }
    }
}
