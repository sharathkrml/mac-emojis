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

            if AXField.apply(range, text: insertion, to: snapshot.element) {
                NSLog("MacEmojis insert: selected text")
                return
            }
            if AXField.replaceValue(range, with: insertion, in: snapshot.element) {
                NSLog("MacEmojis insert: value replace")
                return
            }
            NSLog("MacEmojis insert: paste fallback")
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

        let pasteboard = NSPasteboard.general
        let saved = pasteboard.pasteboardItems?.compactMap { $0.copy() as? NSPasteboardItem } ?? []
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 120_000_000)
            postCommandV()
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard pasteboard.changeCount > 0 else { return }
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
