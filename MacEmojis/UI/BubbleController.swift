import AppKit
import SwiftUI

final class BubblePanel: NSPanel {
    var onKey: ((NSEvent) -> Bool)?
    /// A chip click must not take keyboard focus from the browser, or the paste
    /// that follows lands nowhere. Only the engaged bubble needs to be key.
    var wantsKey = false

    override var canBecomeKey: Bool { wantsKey }
    override var canBecomeMain: Bool { false }

    override func keyDown(with event: NSEvent) {
        if onKey?(event) == true { return }
        super.keyDown(with: event)
    }
}

/// SwiftUI's hosting view ignores the first click in an inactive window by default,
/// which made the first tap on an emoji do nothing.
final class MouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
}

@MainActor
final class BubbleController {
    private var panel: BubblePanel?
    private var model: BubbleModel?
    private var suggestions: [Suggestion] = []
    private var context: SuggestionContext?
    private var snapshot: FieldSnapshot?
    private var selected = 0
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var autoHide: DispatchWorkItem?

    private(set) var isEngaged = false

    func show(suggestions: [Suggestion], context: SuggestionContext, snapshot: FieldSnapshot) {
        guard !suggestions.isEmpty else { return }
        self.suggestions = suggestions
        self.context = context
        self.snapshot = snapshot
        selected = 0
        isEngaged = false

        let model = BubbleModel()
        model.suggestions = suggestions
        self.model = model

        let host = MouseHostingView(rootView: BubbleView(
            model: model,
            opacity: Prefs.opacity,
            onEngage: { [weak self] in self?.engage() },
            onPick: { [weak self] index in self?.pick(index) }
        ))
        let panel = panel ?? makePanel()
        panel.wantsKey = false
        panel.contentView = host
        host.layoutSubtreeIfNeeded()
        let size = host.fittingSize

        let placement = placement(for: size, snapshot: snapshot)
        model.tailAnchor = placement.tailAnchor
        model.tailOnTop = placement.tailOnTop
        present(panel, at: placement.frame)

        installMonitors()
        scheduleAutoHide()
    }

    func hide(reason: String = "") {
        autoHide?.cancel()
        autoHide = nil
        removeMonitors()

        let wasEngaged = isEngaged
        let targetPid = snapshot?.pid
        isEngaged = false
        panel?.wantsKey = false
        panel?.orderOut(nil)
        panel?.alphaValue = 1
        panel?.contentView = nil
        suggestions = []
        context = nil
        snapshot = nil
        model = nil

        if wasEngaged, let targetPid, targetPid != ProcessInfo.processInfo.processIdentifier,
           let app = NSRunningApplication(processIdentifier: targetPid) {
            _ = app.activate(options: [])
        }
    }

    private func engage() {
        guard !isEngaged, let panel, let model else { return }
        isEngaged = true
        autoHide?.cancel()
        panel.wantsKey = true
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        withAnimation(.snappy(duration: 0.22)) {
            model.engaged = true
        }
    }

    private func moveSelection(by delta: Int) {
        guard !suggestions.isEmpty else { return }
        selected = (selected + delta + suggestions.count) % suggestions.count
        withAnimation(.snappy(duration: 0.18)) {
            model?.selected = selected
        }
    }

    private func pick(_ index: Int) {
        guard suggestions.indices.contains(index), let context, let snapshot else { return }
        let emoji = suggestions[index].emoji
        hide(reason: "pick")
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

    private func placement(for size: CGSize, snapshot: FieldSnapshot) -> BubblePlacement {
        var axCaret = snapshot.caretRect
        var axField = snapshot.fieldRect
        var axWindow = snapshot.windowRect

        // Chromium (Brave, Chrome, Electron) reports AX frames in a window-local
        // space. Align them with the on-screen window of the same process and size;
        // native apps already match and shift by zero.
        if let window = axWindow, let origin = AXField.cgWindowOrigin(pid: snapshot.pid, matching: window.size) {
            let aligned = AXField.alignedFrames(
                field: axField,
                caret: axCaret,
                axWindow: window,
                cgOrigin: origin
            )
            axField = aligned.field
            axCaret = aligned.caret
            axWindow = aligned.window
        }

        // A caret far outside its field is a bad frame (Chromium sometimes returns
        // one). The field alone is a reliable anchor.
        if let caret = axCaret, let field = axField,
           !field.insetBy(dx: -24, dy: -24).contains(CGPoint(x: caret.midX, y: caret.midY)) {
            axCaret = nil
        }

        let caret = axCaret.flatMap(AXField.cocoaRect)
        let field = axField.flatMap(AXField.cocoaRect)
        let window = axWindow.flatMap(AXField.cocoaRect) ?? screenFrame(forPID: snapshot.pid)
        let mouse = NSEvent.mouseLocation

        // Pick the screen from the field, not the caret: the field's screen is what
        // the user sees, and Chromium's caret can be bogus.
        let anchorRect = field ?? caret ?? window
        let screen = anchorRect.flatMap { rect in
            NSScreen.screens.first { $0.frame.contains(CGPoint(x: rect.midX, y: rect.midY)) }
        } ?? NSScreen.main ?? NSScreen.screens[0]

        return BubblePlacer.place(
            panelSize: size,
            bleed: BubbleView.bleed,
            caret: caret,
            field: field,
            window: window,
            visible: screen.visibleFrame,
            mouse: mouse
        )
    }

    private func present(_ panel: BubblePanel, at target: NSRect) {
        panel.alphaValue = 0
        panel.setFrame(target.offsetBy(dx: 0, dy: -6), display: false)
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
            panel.animator().setFrame(target, display: true)
        }
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
            let point = NSEvent.mouseLocation
            Task { @MainActor in
                guard let self else { return }
                // A click on the bubble itself must reach a chip, not dismiss it.
                if let panel = self.panel, panel.frame.contains(point) { return }
                self.hide(reason: "globalMonitor")
            }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            guard let self, let panel = self.panel else { return event }
            if event.window !== panel {
                Task { @MainActor in self.hide(reason: "localMonitor") }
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
            Task { @MainActor in self?.hide(reason: "autoHide") }
        }
        autoHide = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 12, execute: item)
    }
}
