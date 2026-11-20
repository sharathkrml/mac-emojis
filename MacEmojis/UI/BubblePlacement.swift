import CoreGraphics

struct BubblePlacement: Equatable {
    let frame: CGRect
    /// Horizontal position of the thought-bubble tail, 0...1 across the bubble.
    let tailAnchor: CGFloat
    /// True when the bubble sits below the text and the tail points up.
    let tailOnTop: Bool
}

enum BubblePlacer {
    static let gap: CGFloat = 8
    static let margin: CGFloat = 8

    /// Places the visible bubble, not the whole panel: `bleed` is the transparent
    /// room around the bubble that the panel carries for its shadow.
    static func place(
        panelSize: CGSize,
        bleed: CGFloat,
        caret: CGRect?,
        field: CGRect?,
        window: CGRect?,
        visible: CGRect,
        mouse: CGPoint
    ) -> BubblePlacement {
        let shape = CGSize(
            width: max(panelSize.width - bleed * 2, 1),
            height: max(panelSize.height - bleed * 2, 1)
        )

        var aboveTop: CGFloat
        var belowBottom: CGFloat
        var anchorX: CGFloat
        var box: CGRect?

        if let caret, caretFits(caret, in: field) {
            anchorX = caret.midX
            box = field
            if let field, hasLinesAbove(caret, in: field) {
                // Show above the whole field so earlier lines stay visible.
                aboveTop = field.maxY
                belowBottom = field.minY
            } else {
                aboveTop = caret.maxY
                belowBottom = field?.minY ?? caret.minY
            }
        } else if let field {
            anchorX = field.midX
            box = field
            aboveTop = field.maxY
            belowBottom = field.minY
        } else if let window {
            anchorX = window.midX
            aboveTop = window.maxY
            belowBottom = window.minY
        } else {
            anchorX = mouse.x
            aboveTop = mouse.y + 16
            belowBottom = mouse.y - 16
        }

        var y = aboveTop + gap - bleed
        var tailOnTop = false
        if y + panelSize.height > visible.maxY - margin {
            let below = belowBottom - gap + bleed - panelSize.height
            if below >= visible.minY + margin {
                y = below
                tailOnTop = true
            } else {
                y = min(max(y, visible.minY + margin), visible.maxY - panelSize.height - margin)
            }
        }

        var x = anchorX - panelSize.width / 2
        if let box, box.width > shape.width + 24 {
            x = min(max(x, box.minX + 12 - bleed), box.maxX - 12 - shape.width - bleed)
        }
        x = min(max(x, visible.minX + margin), visible.maxX - panelSize.width - margin)

        let tailX = (anchorX - (x + bleed)) / shape.width
        return BubblePlacement(
            frame: CGRect(x: x, y: y, width: panelSize.width, height: panelSize.height),
            tailAnchor: min(max(tailX, 0.16), 0.84),
            tailOnTop: tailOnTop
        )
    }

    private static func caretFits(_ caret: CGRect, in field: CGRect?) -> Bool {
        guard let field else { return true }
        return field.insetBy(dx: -200, dy: -200).contains(CGPoint(x: caret.midX, y: caret.midY))
    }

    /// True when the caret is not on the first line of a multi-line field.
    static func hasLinesAbove(_ caret: CGRect, in field: CGRect) -> Bool {
        field.maxY - caret.maxY > caret.height * 1.2
    }
}
