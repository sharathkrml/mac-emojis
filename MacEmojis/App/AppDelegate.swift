import AppKit
import SwiftUI

final class PanelWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// SwiftUI ignores the click that activates an inactive window; these panels should
/// respond on the first click, like the suggestion bubble does.
final class PanelHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let enabledItem = NSMenuItem(title: "Enabled", action: nil, keyEquivalent: "")
    private let monitor = TextMonitor()
    private let bubble = BubbleController()
    private var window: NSWindow?
    private var defaultsObserver: NSObjectProtocol?

    /// Transparent margin around each panel so its SwiftUI shadow has room.
    private let shadowInset: CGFloat = 26

    func applicationDidFinishLaunching(_ notification: Notification) {
        Prefs.registerDefaults()
        monitor.bubble = bubble
        buildMenu()

        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.syncEnabled() }
        }
        syncEnabled()

        if !UserDefaults.standard.bool(forKey: Prefs.onboardedKey) {
            DispatchQueue.main.async { self.openOnboarding() }
        }
    }

    private func buildMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "face.smiling", accessibilityDescription: "MacEmojis")
        statusItem.button?.image?.isTemplate = true

        let menu = NSMenu()

        let about = NSMenuItem(title: "About MacEmojis", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)
        menu.addItem(.separator())

        enabledItem.target = self
        enabledItem.action = #selector(toggleEnabled)
        menu.addItem(enabledItem)
        menu.addItem(.separator())

        let settings = NSMenuItem(title: "Settings…", action: #selector(openWindow), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        let github = NSMenuItem(title: "MacEmojis on GitHub", action: #selector(openGitHub), keyEquivalent: "")
        github.target = self
        menu.addItem(github)

        let issues = NSMenuItem(title: "Report an Issue…", action: #selector(openIssues), keyEquivalent: "")
        issues.target = self
        menu.addItem(issues)
        menu.addItem(.separator())

        menu.addItem(NSMenuItem(title: "Quit MacEmojis", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    @objc private func showAbout() {
        let credits = NSMutableAttributedString(
            string: "On-device emoji suggestions for macOS.\n\nPowered by Desert Ant Labs 🐜\nhttps://desertant.com/\n\nMIT License",
            attributes: [.font: NSFont.systemFont(ofSize: 11)]
        )
        if let range = credits.string.range(of: "https://desertant.com/") {
            credits.addAttribute(
                .link,
                value: "https://desertant.com/",
                range: NSRange(range, in: credits.string)
            )
        }
        NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openGitHub() {
        open("https://github.com/sharathkrml/mac-emojis")
    }

    @objc private func openIssues() {
        open("https://github.com/sharathkrml/mac-emojis/issues/new/choose")
    }

    private func open(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }

    private func syncEnabled() {
        let enabled = Prefs.enabled
        enabledItem.state = enabled ? .on : .off
        if enabled {
            monitor.start()
        } else {
            monitor.stop()
        }
    }

    @objc private func toggleEnabled() {
        UserDefaults.standard.set(!Prefs.enabled, forKey: Prefs.enabledKey)
        syncEnabled()
    }

    @objc private func openWindow() {
        present(
            MainView(onClose: { [weak self] in self?.closeWindow() })
                .environmentObject(EmoService.shared),
            panelSize: CGSize(width: 560, height: 700)
        )
    }

    private func openOnboarding() {
        present(
            OnboardingView(
                onFinish: { [weak self] in self?.closeWindow() },
                onClose: { [weak self] in self?.closeWindow() }
            )
            .environmentObject(EmoService.shared),
            panelSize: CGSize(width: 520, height: 600)
        )
    }

    private func present<Content: View>(_ content: Content, panelSize: CGSize) {
        window?.close()

        let frame = NSRect(
            x: 0,
            y: 0,
            width: panelSize.width + shadowInset * 2,
            height: panelSize.height + shadowInset * 2
        )
        let panel = PanelWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        panel.title = "MacEmojis"
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.collectionBehavior = [.fullScreenAuxiliary]
        panel.contentView = PanelHostingView(rootView: content.padding(shadowInset))
        panel.center()
        panel.alphaValue = 0

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.22
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
        window = panel
    }

    private func closeWindow() {
        window?.close()
        window = nil
    }
}
