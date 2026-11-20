import SwiftUI

struct BubbleView: View {
    let emojis: [String]
    let engaged: Bool
    let selected: Int
    let opacity: Double
    let onEngage: () -> Void
    let onPick: (Int) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(emojis.enumerated()), id: \.offset) { index, emoji in
                Text(emoji)
                    .font(.system(size: 26))
                    .frame(width: 44, height: 44)
                    .background {
                        if engaged && selected == index {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.accentColor.opacity(0.28))
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { onPick(index) }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(.regularMaterial)
                .contentShape(Capsule())
                .onTapGesture {
                    if !engaged { onEngage() }
                }
        }
        .overlay {
            Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.28), radius: 10, y: 4)
        .opacity(opacity)
    }
}
