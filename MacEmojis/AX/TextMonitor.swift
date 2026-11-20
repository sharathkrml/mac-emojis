import AppKit

@MainActor
final class TextMonitor {
    weak var bubble: BubbleController?

    private var timer: Timer?
    private var lastIdentity: String?
    private var lastChange = Date.distantPast
    private var shownIdentity: String?
    private var generation = 0
    private var preparedApps: Set<pid_t> = []

    func start() {
        guard timer == nil else { return }
        let timer = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        reset()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        generation += 1
        bubble?.hide(reason: "stop")
        reset()
    }

    private func reset() {
        lastIdentity = nil
        shownIdentity = nil
        lastChange = .distantPast
    }

    private func tick() {
        guard Prefs.enabled else { return }
        guard !(bubble?.isEngaged ?? false) else { return }

        // Chromium and Electron keep their accessibility tree dormant until a client
        // switches it on. Do that once for whatever app is in front; native apps are
        // already accessible and return immediately.
        if let app = NSWorkspace.shared.frontmostApplication,
           !preparedApps.contains(app.processIdentifier),
           AXField.prepareAccessibility(pid: app.processIdentifier, bundleID: app.bundleIdentifier) {
            preparedApps.insert(app.processIdentifier)
        }

        // Clicking the bubble makes the system AX focus unreadable for ~100 ms;
        // deciding during a held button tears the panel down mid-tap (missed clicks).
        guard NSEvent.pressedMouseButtons == 0 else { return }

        guard let snapshot = AXField.focused() else {
            if lastIdentity != nil {
                reset()
                bubble?.hide(reason: "noField")
            }
            return
        }

        // Our own test field works without Accessibility trust; other apps do not.
        guard snapshot.isOurs || AXField.isTrusted() else { return }

        if snapshot.identity != lastIdentity {
            NSLog("[DEBUG-hx7] identityChange sel=\(snapshot.selection) len=\(snapshot.value.count) prev=\(lastIdentity ?? "nil")")
            lastIdentity = snapshot.identity
            lastChange = Date()
            shownIdentity = nil
            bubble?.hide(reason: "identityChange")
            return
        }

        guard shownIdentity != snapshot.identity else { return }
        guard Date().timeIntervalSince(lastChange) >= Prefs.pause else { return }
        shownIdentity = snapshot.identity
        requestSuggestions(for: snapshot)
    }

    private func requestSuggestions(for snapshot: FieldSnapshot) {
        let context: SuggestionContext?
        if snapshot.selection.length > 0 {
            context = Sentence.selectionContext(
                value: snapshot.value,
                selection: snapshot.selection,
                enabled: Prefs.selectionEnabled
            )
        } else {
            context = Sentence.context(
                value: snapshot.value,
                caret: snapshot.selection.location,
                replaceEnabled: Prefs.replaceEnabled,
                sentenceEnabled: Prefs.sentenceEnabled
            )
        }
        guard let context else { return }

        let query: String
        switch context {
        case .sentence(let text, _), .selection(let text, _): query = text
        case .replace(let word, _): query = word
        }

        generation += 1
        let generation = generation

        Task { @MainActor [weak self] in
            guard let self else { return }
            var emojis = await EmoService.shared.suggestions(for: query)
            guard generation == self.generation else { return }

            emojis = emojis.filter { !query.contains($0) }
            guard !emojis.isEmpty else { return }

            self.bubble?.show(emojis: emojis, context: context, snapshot: snapshot)
        }
    }
}
