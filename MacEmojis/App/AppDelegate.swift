import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let enabledItem = NSMenuItem(title: "Enabled", action: nil, keyEquivalent: "")
    private let monitor = TextMonitor()
    private let bubble = BubbleController()
    private var window: NSWindow?
    private var defaultsObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Prefs.registerDefaults()
        NSLog("MacEmojis trust=%d path=%@", AXField.isTrusted() ? 1 : 0, Bundle.main.bundlePath)
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
            DispatchQueue.main.async { self.openWindow() }
        }
    }

    private func buildMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "face.smiling", accessibilityDescription: "MacEmojis")
        statusItem.button?.image?.isTemplate = true

        let menu = NSMenu()
        enabledItem.target = self
        enabledItem.action = #selector(toggleEnabled)
        menu.addItem(enabledItem)
        menu.addItem(.separator())

        let settings = NSMenuItem(title: "Settings…", action: #selector(openWindow), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit MacEmojis", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
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
        if window == nil {
            let hosting = NSHostingController(rootView: MainView().environmentObject(EmoService.shared))
            let window = NSWindow(contentViewController: hosting)
            window.title = "MacEmojis"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
