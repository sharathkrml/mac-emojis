import AppKit
import SwiftUI

final class BubblePanel: NSPanel {
    var onKey: ((NSEvent) -> Bool)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func keyDown(with event: NSEvent) {
        if onKey?(event) == true { return }
        super.keyDown(with: event)
    }
}

/// SwiftUI's hosting view ignores the first click in an inactive window by default,
/// which made the first tap on an emoji do nothing.
final class MouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

@MainActor
final class BubbleController {
    private var panel: BubblePanel?
    private var host: MouseHostingView<BubbleView>?
    private var emojis: [String] = []
    private var context: SuggestionContext?
    private var snapshot: FieldSnapshot?
    private var selected = 0
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var autoHide: DispatchWorkItem?

    private(set) var isEngaged = false

    func show(emojis: [String], context: SuggestionContext, snapshot: FieldSnapshot) {
        guard !emojis.isEmpty else { return }
        self.emojis = emojis
        self.context = context
        self.snapshot = snapshot
        selected = 0
        isEngaged = false

        let host = MouseHostingView(rootView: view(engaged: false))
        let panel = panel ?? makePanel()
        panel.contentView = host
        host.layoutSubtreeIfNeeded()
        let size = host.fittingSize
        self.host = host
        panel.setFrame(frame(for: size, snapshot: snapshot), display: true)
        panel.orderFrontRegardless()

        installMonitors()
        scheduleAutoHide()
    }

    func hide() {
        autoHide?.cancel()
        autoHide = nil
        removeMonitors()

        let wasEngaged = isEngaged
        let targetPid = snapshot?.pid
        isEngaged = false
        panel?.orderOut(nil)
        emojis = []
        context = nil
        snapshot = nil

        if wasEngaged, let targetPid, targetPid != ProcessInfo.processInfo.processIdentifier,
           let app = NSRunningApplication(processIdentifier: targetPid) {
            _ = app.activate(options: [])
        }
    }

    private func engage() {
        guard !isEngaged, let panel else { return }
        isEngaged = true
        autoHide?.cancel()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        render()
    }

    private func moveSelection(by delta: Int) {
        guard !emojis.isEmpty else { return }
        selected = (selected + delta + emojis.count) % emojis.count
        render()
    }

    private func pick(_ index: Int) {
        guard emojis.indices.contains(index), let context, let snapshot else { return }
        let emoji = emojis[index]
        hide()
        Inserter.insert(emoji, context: context, snapshot: snapshot)
    }

    private func handleKey(_ event: NSEvent) -> Bool {
        switch event.keyCode {
        case 123: moveSelection(by: -1); return true
        case 124: moveSelection(by: 1); return true
        case 36, 76: pick(selected); return true
        case 53: hide(); return true
        default: return false
        }
    }

    private func view(engaged: Bool) -> BubbleView {
        BubbleView(
            emojis: emojis,
            engaged: engaged,
            selected: selected,
            opacity: Prefs.opacity,
            onEngage: { [weak self] in self?.engage() },
            onPick: { [weak self] index in self?.pick(index) }
        )
    }

    private func render() {
        host?.rootView = view(engaged: isEngaged)
    }

    private func makePanel() -> BubblePanel {
        let panel = BubblePanel(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 56),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovable = false
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.onKey = { [weak self] event in self?.handleKey(event) ?? false }
        self.panel = panel
        return panel
    }

    private func frame(for size: CGSize, snapshot: FieldSnapshot) -> NSRect {
        let caret = snapshot.caretRect.flatMap(AXField.cocoaRect)
        let field = snapshot.fieldRect.flatMap(AXField.cocoaRect)
        let axWindow = snapshot.windowRect.flatMap(AXField.cocoaRect)
        let window = axWindow ?? screenFrame(forPID: snapshot.pid)

        var anchor: CGRect?
        var isCaret = false
        if let caret, field.map({
            $0.insetBy(dx: -200, dy: -200).contains(CGPoint(x: caret.midX, y: caret.midY))
        }) ?? true {
            anchor = caret
            isCaret = true
        } else if let field {
            anchor = field
        } else if let window {
            anchor = window
        }

        let mouse = NSEvent.mouseLocation
        let point = anchor.map { CGPoint(x: $0.midX, y: $0.midY) } ?? mouse
        let screen = NSScreen.screens.first(where: { $0.frame.contains(point) })
            ?? NSScreen.main
            ?? NSScreen.screens[0]
        let visible = screen.visibleFrame

        guard let anchor else {
            return NSRect(
                x: min(max(mouse.x + 12, visible.minX + 8), visible.maxX - size.width - 8),
                y: min(max(mouse.y - size.height - 12, visible.minY + 8), visible.maxY - size.height - 8),
                width: size.width,
                height: size.height
            )
        }

        var x = anchor.midX - size.width / 2
        var y: CGFloat
        if isCaret {
            y = anchor.maxY + 8
            if y + size.height > visible.maxY {
                y = anchor.minY - size.height - 8
            }
        } else {
            // A field/window fallback: float near the top edge of that region, inside the screen.
            y = anchor.maxY - size.height - 10
            if y < visible.minY {
                y = anchor.minY + 10
            }
        }
        x = min(max(x, visible.minX + 8), visible.maxX - size.width - 8)
        y = min(max(y, visible.minY + 8), visible.maxY - size.height - 8)
        return NSRect(x: x, y: y, width: size.width, height: size.height)
    }

    /// Last-resort anchor on the right screen when the app exposes no usable AX bounds.
    private func screenFrame(forPID pid: pid_t) -> CGRect? {
        guard let windows = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else { return nil }

        let rects: [CGRect] = windows.compactMap { info in
            guard (info[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value == pid,
                  (info[kCGWindowLayer as String] as? NSNumber)?.intValue == 0,
                  let bounds = info[kCGWindowBounds as String] as? [String: Any] else { return nil }
            let rect = CGRect(
                x: (bounds["X"] as? NSNumber)?.doubleValue ?? 0,
                y: (bounds["Y"] as? NSNumber)?.doubleValue ?? 0,
                width: (bounds["Width"] as? NSNumber)?.doubleValue ?? 0,
                height: (bounds["Height"] as? NSNumber)?.doubleValue ?? 0
            )
            return rect.width > 40 && rect.height > 40 ? rect : nil
        }
        let largest = rects.max { $0.width * $0.height < $1.width * $1.height }
        return largest.flatMap(AXField.cocoaRect)
    }

    private func installMonitors() {
        removeMonitors()
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in self?.hide() }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            guard let self, let panel = self.panel else { return event }
            if event.window !== panel {
                Task { @MainActor in self.hide() }
            }
            return event
        }
    }

    private func removeMonitors() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }

    private func scheduleAutoHide() {
        autoHide?.cancel()
        let item = DispatchWorkItem { [weak self] in
            Task { @MainActor in self?.hide() }
        }
        autoHide = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 12, execute: item)
    }
}
