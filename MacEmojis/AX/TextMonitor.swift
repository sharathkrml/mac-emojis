import AppKit

@MainActor
final class TextMonitor {
    weak var bubble: BubbleController?

    private var timer: Timer?
    private var lastIdentity: String?
    private var lastChange = Date.distantPast
    private var shownIdentity: String?
    private var generation = 0

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
        bubble?.hide()
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

        guard let snapshot = AXField.focused() else {
            if lastIdentity != nil {
                reset()
                bubble?.hide()
            }
            return
        }

        // Our own test field works without Accessibility trust; other apps do not.
        guard snapshot.isOurs || AXField.isTrusted() else { return }
        guard snapshot.selection.length == 0 else { return }

        if snapshot.identity != lastIdentity {
            lastIdentity = snapshot.identity
            lastChange = Date()
            shownIdentity = nil
            bubble?.hide()
            return
        }

        guard shownIdentity != snapshot.identity else { return }
        guard Date().timeIntervalSince(lastChange) >= Prefs.pause else { return }
        shownIdentity = snapshot.identity
        requestSuggestions(for: snapshot)
    }

    private func requestSuggestions(for snapshot: FieldSnapshot) {
        guard let context = Sentence.context(
            value: snapshot.value,
            caret: snapshot.selection.location,
            replaceEnabled: Prefs.replaceEnabled,
            sentenceEnabled: Prefs.sentenceEnabled
        ) else { return }

        let query: String
        switch context {
        case .sentence(let text, _): query = text
        case .replace(let word, _): query = word
        }

        generation += 1
        let generation = generation

        Task { @MainActor [weak self] in
            guard let self else { return }
            var emojis = await EmoService.shared.suggestions(for: query)
            guard generation == self.generation else { return }

            if case .sentence(let sentence, _) = context {
                emojis = emojis.filter { !sentence.contains($0) }
            }
            guard !emojis.isEmpty else { return }

            self.bubble?.show(emojis: emojis, context: context, snapshot: snapshot)
        }
    }
}
