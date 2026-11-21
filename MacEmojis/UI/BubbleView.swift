import SwiftUI

@MainActor
final class BubbleModel: ObservableObject {
    @Published var suggestions: [Suggestion] = []
    @Published var engaged = false
    @Published var selected = 0
    @Published var tailAnchor: CGFloat = 0.5
    @Published var tailOnTop = false
}

struct BubbleView: View {
    /// Transparent room around the bubble, kept for the drop shadow.
    static let bleed: CGFloat = 14

    private static let cell = CGSize(width: 42, height: 42)
    private static let spacing: CGFloat = 2
    private static let inset: CGFloat = 7

    @ObservedObject var model: BubbleModel
    let opacity: Double
    let onEngage: () -> Void
    let onPick: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false

    var body: some View {
        VStack(spacing: 2) {
            if model.tailOnTop { tail }
            bubble
            if !model.tailOnTop { tail }
        }
        .padding(Self.bleed)
        .opacity(opacity)
        .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
        // The bubble grows out of its tail, toward the caret it points at.
        .scaleEffect(revealed ? 1 : 0.82, anchor: revealAnchor)
        .offset(y: revealed ? 0 : (model.tailOnTop ? -10 : 10))
        .opacity(revealed ? 1 : 0)
        .animation(.snappy(duration: 0.18), value: model.selected)
        .animation(.snappy(duration: 0.18), value: model.engaged)
        .onAppear {
            // show() sets the tail anchor right after attaching this view; wait a
            // turn so the entrance scales from the final tail, not the default.
            DispatchQueue.main.async {
                guard !reduceMotion else {
                    revealed = true
                    return
                }
                withAnimation(.spring(response: 0.26, dampingFraction: 0.82)) {
                    revealed = true
                }
            }
        }
    }

    private var bubble: some View {
        HStack(spacing: Self.spacing) {
            ForEach(Array(model.suggestions.enumerated()), id: \.offset) { index, suggestion in
                EmojiChip(
                    suggestion: suggestion,
                    index: index,
                    selected: model.engaged && model.selected == index,
                    engaged: model.engaged,
                    onPick: { onPick(index) }
                )
            }
        }
        .padding(.horizontal, Self.inset)
        .padding(.vertical, 5)
        .background(.regularMaterial, in: bubbleShape)
        .overlay {
            bubbleShape.strokeBorder(
                model.engaged ? Color.accentColor.opacity(0.55) : Color.white.opacity(0.22),
                lineWidth: 1
            )
        }
        .contentShape(bubbleShape)
        .onTapGesture {
            if !model.engaged { onEngage() }
        }
    }

    private var bubbleShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
    }

    /// Three detached puffs trailing toward the caret, like a thought bubble.
    private var tail: some View {
        let width = Self.contentWidth(count: model.suggestions.count)
        let x = tailX(width: width)
        let sizes: [CGFloat] = model.tailOnTop ? [4, 7, 10] : [10, 7, 4]
        let offsets: [(CGFloat, CGFloat)] = [(-8, 0), (1, 10), (-3, 20)]

        return ZStack(alignment: .topLeading) {
            ForEach(Array(sizes.enumerated()), id: \.offset) { index, size in
                Circle()
                    .fill(.regularMaterial)
                    .overlay(Circle().strokeBorder(.white.opacity(0.22), lineWidth: 0.75))
                    .frame(width: size, height: size)
                    .offset(x: x + offsets[index].0, y: offsets[index].1)
            }
        }
        .frame(width: width, height: 26, alignment: .topLeading)
    }

    private func tailX(width: CGFloat) -> CGFloat {
        min(max(model.tailAnchor * width, 12), width - 12)
    }

    /// Center the entrance scale on the tail, so the bubble swells from the caret.
    private var revealAnchor: UnitPoint {
        let width = Self.contentWidth(count: model.suggestions.count)
        return UnitPoint(
            x: (Self.bleed + tailX(width: width)) / (width + Self.bleed * 2),
            y: model.tailOnTop ? 0 : 1
        )
    }

    static func contentWidth(count: Int) -> CGFloat {
        CGFloat(count) * cell.width
            + CGFloat(max(0, count - 1)) * spacing
            + inset * 2
    }
}

private struct EmojiChip: View {
    let suggestion: Suggestion
    let index: Int
    let selected: Bool
    let engaged: Bool
    let onPick: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var hovered = false

    private var value: String {
        String(format: "%.2f", suggestion.confidence)
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(suggestion.emoji)
                .font(.system(size: 26))
            Text(value)
                .font(.system(size: 8, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .scaleEffect(appeared ? scale : 0.5)
        .offset(y: appeared ? 0 : 6)
        .frame(width: 42, height: 48)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(highlight)
        }
        .opacity(appeared ? 1 : 0)
        .contentShape(Rectangle())
        .accessibilityLabel("Insert \(suggestion.emoji), score \(value)")
        .accessibilityAddTraits(.isButton)
        .onTapGesture(perform: onPick)
        .onHover { inside in
            withAnimation(.snappy(duration: 0.16)) { hovered = inside }
        }
        .onAppear {
            guard !reduceMotion else {
                appeared = true
                return
            }
            // Let the bubble land first, then the emoji pop in behind the tail.
            withAnimation(.spring(response: 0.28, dampingFraction: 0.6).delay(0.14 + Double(index) * 0.03)) {
                appeared = true
            }
        }
    }

    private var scale: CGFloat {
        if hovered { return 1.16 }
        return selected ? 1.08 : 1
    }

    private var highlight: Color {
        if selected { return Color.accentColor.opacity(0.3) }
        if hovered { return Color.primary.opacity(engaged ? 0.08 : 0.04) }
        return .clear
    }
}
