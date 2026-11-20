import AppKit
import ApplicationServices
import Carbon

struct FieldSnapshot {
    let pid: pid_t
    let appName: String
    let element: AXUIElement
    let value: String
    let selection: NSRange
    /// Caret bounds in Accessibility coordinates (origin top-left of the primary display).
    let caretRect: CGRect?
    let fieldRect: CGRect?
    let windowRect: CGRect?

    var isOurs: Bool { pid == ProcessInfo.processInfo.processIdentifier }

    var identity: String {
        "\(pid)|\(selection.location)|\(selection.length)|\(value.hashValue)"
    }
}

enum AXField {
    static func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    static func promptForAccess() {
        _ = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    static func focused() -> FieldSnapshot? {
        guard !IsSecureEventInputEnabled() else { return nil }

        let system = AXUIElementCreateSystemWide()
        guard let focused = attribute(system, kAXFocusedUIElementAttribute),
              CFGetTypeID(focused) == AXUIElementGetTypeID() else { return nil }
        let element = focused as! AXUIElement

        var pid: pid_t = 0
        AXUIElementGetPid(element, &pid)
        guard pid > 0, let app = NSRunningApplication(processIdentifier: pid) else { return nil }

        let role = attribute(element, kAXRoleAttribute) as? String ?? ""
        let subrole = attribute(element, kAXSubroleAttribute) as? String ?? ""
        guard ["AXTextField", "AXTextArea", "AXComboBox", "AXSearchField"].contains(role),
              subrole != "AXSecureTextField" else { return nil }

        guard let value = attribute(element, kAXValueAttribute) as? String,
              let selection = selectedRange(element) else { return nil }
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selection.location > 0 else {
            return nil
        }

        return FieldSnapshot(
            pid: pid,
            appName: app.localizedName ?? "app",
            element: element,
            value: value,
            selection: selection,
            caretRect: bounds(for: element, range: NSRange(location: selection.location, length: 0)),
            fieldRect: frame(of: element),
            windowRect: focusedWindowFrame()
        )
    }

    static func apply(_ range: NSRange, text: String, to element: AXUIElement) -> Bool {
        AXUIElementSetAttributeValue(element, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        guard let axRange = axValue(range),
              AXUIElementSetAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, axRange) == .success,
              AXUIElementSetAttributeValue(
                  element,
                  kAXSelectedTextAttribute as CFString,
                  text as CFString
              ) == .success,
              contains(text, at: range, in: element) else {
            return false
        }
        setCaret(element, range.location + (text as NSString).length)
        return true
    }

    /// Some apps accept `AXSelectedText` but ignore it. Rewriting `AXValue` catches those.
    static func replaceValue(_ range: NSRange, with text: String, in element: AXUIElement) -> Bool {
        guard let current = attribute(element, kAXValueAttribute) as? String else { return false }
        let ns = current as NSString
        guard range.location >= 0, range.location + range.length <= ns.length else { return false }
        let updated = ns.replacingCharacters(in: range, with: text)
        guard AXUIElementSetAttributeValue(element, kAXValueAttribute as CFString, updated as CFString) == .success else {
            return false
        }
        setCaret(element, range.location + (text as NSString).length)
        return true
    }

    static func select(_ range: NSRange, in element: AXUIElement) {
        guard let axRange = axValue(range) else { return }
        AXUIElementSetAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, axRange)
    }

    static func cocoaRect(fromAX rect: CGRect) -> CGRect? {
        // AX origin is the top-left of the primary display, which is the screen whose
        // Cocoa frame origin is (0, 0) — not necessarily `screens.first`.
        guard let primary = NSScreen.screens.first(where: { $0.frame.origin == .zero }) ?? NSScreen.screens.first else {
            return nil
        }
        let height = primary.frame.height
        return CGRect(
            x: rect.minX,
            y: height - rect.maxY,
            width: max(rect.width, 1),
            height: max(rect.height, 1)
        )
    }

    // MARK: - Helpers

    private static func setCaret(_ element: AXUIElement, _ location: Int) {
        var range = CFRange(location: location, length: 0)
        if let value = AXValueCreate(.cfRange, &range) {
            AXUIElementSetAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, value)
        }
    }

    private static func contains(_ text: String, at range: NSRange, in element: AXUIElement) -> Bool {
        guard let value = attribute(element, kAXValueAttribute) as? String else { return true }
        let ns = value as NSString
        let length = (text as NSString).length
        guard range.location >= 0, range.location + length <= ns.length else { return false }
        return ns.substring(with: NSRange(location: range.location, length: length)) == text
    }

    private static func focusedWindowFrame() -> CGRect? {
        let system = AXUIElementCreateSystemWide()
        guard let raw = attribute(system, kAXFocusedWindowAttribute),
              CFGetTypeID(raw) == AXUIElementGetTypeID() else { return nil }
        return frame(of: raw as! AXUIElement)
    }

    private static func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }

    private static func selectedRange(_ element: AXUIElement) -> NSRange? {
        guard let raw = attribute(element, kAXSelectedTextRangeAttribute),
              CFGetTypeID(raw) == AXValueGetTypeID() else { return nil }
        var range = CFRange()
        guard AXValueGetValue(raw as! AXValue, .cfRange, &range) else { return nil }
        return NSRange(location: max(0, range.location), length: max(0, range.length))
    }

    private static func bounds(for element: AXUIElement, range: NSRange) -> CGRect? {
        for length in [0, 1] {
            guard let axRange = axValue(NSRange(location: range.location, length: length)) else { continue }
            var raw: CFTypeRef?
            guard AXUIElementCopyParameterizedAttributeValue(
                element,
                kAXBoundsForRangeParameterizedAttribute as CFString,
                axRange,
                &raw
            ) == .success, let raw, CFGetTypeID(raw) == AXValueGetTypeID() else { continue }
            var rect = CGRect.zero
            if AXValueGetValue(raw as! AXValue, .cgRect, &rect), rect.width.isFinite, rect.height.isFinite {
                return rect
            }
        }
        return nil
    }

    private static func frame(of element: AXUIElement) -> CGRect? {
        guard let position = attribute(element, kAXPositionAttribute),
              let size = attribute(element, kAXSizeAttribute),
              CFGetTypeID(position) == AXValueGetTypeID(),
              CFGetTypeID(size) == AXValueGetTypeID() else { return nil }
        var point = CGPoint.zero
        var dimensions = CGSize.zero
        guard AXValueGetValue(position as! AXValue, .cgPoint, &point),
              AXValueGetValue(size as! AXValue, .cgSize, &dimensions) else { return nil }
        return CGRect(origin: point, size: dimensions)
    }

    private static func axValue(_ range: NSRange) -> AXValue? {
        var cfRange = CFRange(location: range.location, length: range.length)
        return AXValueCreate(.cfRange, &cfRange)
    }
}
