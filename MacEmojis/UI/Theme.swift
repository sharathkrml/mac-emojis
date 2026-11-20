import SwiftUI

/// Shared look for the floating onboarding and settings panels.
enum Theme {
    static let panel = Color(red: 0.024, green: 0.024, blue: 0.028)
    static let card = Color(red: 0.076, green: 0.076, blue: 0.084)
    static let cardStrong = Color(red: 0.10, green: 0.10, blue: 0.11)
    static let hairline = Color.white.opacity(0.07)
    static let text = Color.white.opacity(0.94)
    static let text2 = Color.white.opacity(0.55)
    static let text3 = Color.white.opacity(0.36)

    static let blue = Color(red: 0.19, green: 0.46, blue: 0.97)
    static let blueBright = Color(red: 0.33, green: 0.60, blue: 1.0)
    static let cyan = Color(red: 0.46, green: 0.73, blue: 1.0)
    static let orange = Color(red: 0.84, green: 0.36, blue: 0.07)
    static let peach = Color(red: 1.0, green: 0.62, blue: 0.30)
    static let ember = Color(red: 0.48, green: 0.11, blue: 0.03)
    static let green = Color(red: 0.20, green: 0.83, blue: 0.38)
    static let amber = Color(red: 1.0, green: 0.62, blue: 0.04)

    static let closeRed = Color(red: 1.0, green: 0.27, blue: 0.23)
}

// MARK: - Panel

/// Rounded black panel with the warm/blue aurora, a hairline rim and a shadow.
struct PanelChrome<Content: View>: View {
    let size: CGSize
    var auroraHeight: CGFloat = 380
    var auroraOpacity: Double = 1
    var onClose: (() -> Void)?
    @ViewBuilder var content: () -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            ZStack(alignment: .top) {
                Theme.panel
                Aurora()
                    .frame(height: auroraHeight)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .opacity(auroraOpacity)
            }
            content()
                .frame(width: size.width, height: size.height)
            if let onClose {
                CloseDot(action: onClose)
                    .padding(16)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(0.55), radius: 30, y: 18)
        .scaleEffect(shown ? 1 : 0.96)
        .opacity(shown ? 1 : 0)
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.86)) {
                shown = true
            }
        }
        .environment(\.colorScheme, .dark)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
    }
}

struct CloseDot: View {
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.38, blue: 0.34), Theme.closeRed],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(Circle().strokeBorder(Color.white.opacity(0.18), lineWidth: 0.75))
                .overlay {
                    if hovered {
                        Image(systemName: "xmark")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.black.opacity(0.55))
                    }
                }
                .frame(width: 13, height: 13)
                .scaleEffect(hovered ? 1.08 : 1)
        }
        .buttonStyle(.plain)
        .onHover { inside in
            withAnimation(.easeOut(duration: 0.12)) { hovered = inside }
        }
        .accessibilityLabel("Close")
    }
}

// MARK: - Aurora

/// Two soft circular ribbons — warm on the left, blue on the right — over pure black.
/// The inner edges are traced with a thin rim so they read as ribbons, not blobs.
struct Aurora: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drifting = false

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            // Warm crescent: a filled wedge on the left, bright toward its top-left.
            var warm = Path()
            warm.move(to: CGPoint(x: -0.06 * w, y: -0.06 * h))
            warm.addCurve(
                to: CGPoint(x: 0.50 * w, y: 0.44 * h),
                control1: CGPoint(x: 0.36 * w, y: -0.02 * h),
                control2: CGPoint(x: 0.47 * w, y: 0.22 * h)
            )
            warm.addCurve(
                to: CGPoint(x: 0.38 * w, y: 0.86 * h),
                control1: CGPoint(x: 0.53 * w, y: 0.62 * h),
                control2: CGPoint(x: 0.52 * w, y: 0.78 * h)
            )
            warm.addCurve(
                to: CGPoint(x: -0.10 * w, y: 1.04 * h),
                control1: CGPoint(x: 0.20 * w, y: 0.99 * h),
                control2: CGPoint(x: 0.02 * w, y: 1.02 * h)
            )
            warm.closeSubpath()

            context.drawLayer { layer in
                layer.addFilter(.blur(radius: 16))
                layer.fill(
                    warm,
                    with: .radialGradient(
                        Gradient(colors: [
                            Theme.peach.opacity(0.95),
                            Theme.orange.opacity(0.80),
                            Theme.ember.opacity(0.55),
                            .clear,
                        ]),
                        center: CGPoint(x: 0.02 * w, y: 0.04 * h),
                        startRadius: 0,
                        endRadius: 0.62 * w
                    )
                )
            }

            // Red under-glow along the crescent's inner edge.
            var glow = Path()
            glow.move(to: CGPoint(x: 0.30 * w, y: 0.05 * h))
            glow.addCurve(
                to: CGPoint(x: 0.30 * w, y: 0.80 * h),
                control1: CGPoint(x: 0.55 * w, y: 0.30 * h),
                control2: CGPoint(x: 0.48 * w, y: 0.65 * h)
            )
            context.drawLayer { layer in
                layer.addFilter(.blur(radius: 40))
                layer.stroke(
                    glow,
                    with: .color(Theme.orange.opacity(0.24)),
                    style: StrokeStyle(lineWidth: 64, lineCap: .round)
                )
            }

            // Blue crescent on the right; its lower-left edge is the bright wave.
            var blue = Path()
            blue.move(to: CGPoint(x: 0.58 * w, y: -0.08 * h))
            blue.addCurve(
                to: CGPoint(x: 1.04 * w, y: 0.20 * h),
                control1: CGPoint(x: 0.96 * w, y: -0.10 * h),
                control2: CGPoint(x: 1.05 * w, y: 0.06 * h)
            )
            blue.addCurve(
                to: CGPoint(x: 0.55 * w, y: 0.52 * h),
                control1: CGPoint(x: 1.02 * w, y: 0.44 * h),
                control2: CGPoint(x: 0.82 * w, y: 0.36 * h)
            )
            blue.addCurve(
                to: CGPoint(x: 0.62 * w, y: 0.72 * h),
                control1: CGPoint(x: 0.44 * w, y: 0.60 * h),
                control2: CGPoint(x: 0.46 * w, y: 0.70 * h)
            )
            blue.addLine(to: CGPoint(x: 1.12 * w, y: 0.86 * h))
            blue.addLine(to: CGPoint(x: 1.12 * w, y: -0.10 * h))
            blue.closeSubpath()

            context.drawLayer { layer in
                layer.addFilter(.blur(radius: 16))
                layer.fill(
                    blue,
                    with: .radialGradient(
                        Gradient(colors: [
                            Theme.blueBright.opacity(0.88),
                            Theme.blue.opacity(0.68),
                            Color(red: 0.02, green: 0.05, blue: 0.22).opacity(0.68),
                            .clear,
                        ]),
                        center: CGPoint(x: 0.92 * w, y: 0.14 * h),
                        startRadius: 0,
                        endRadius: 0.70 * w
                    )
                )
            }

            // Thin bright rim tracing the blue's inner wave, plus a soft halo.
            var rim = Path()
            rim.move(to: CGPoint(x: 0.62 * w, y: -0.02 * h))
            rim.addCurve(
                to: CGPoint(x: 0.99 * w, y: 0.24 * h),
                control1: CGPoint(x: 0.92 * w, y: -0.04 * h),
                control2: CGPoint(x: 1.02 * w, y: 0.08 * h)
            )
            rim.addCurve(
                to: CGPoint(x: 0.56 * w, y: 0.50 * h),
                control1: CGPoint(x: 0.97 * w, y: 0.43 * h),
                control2: CGPoint(x: 0.80 * w, y: 0.35 * h)
            )
            rim.addCurve(
                to: CGPoint(x: 0.64 * w, y: 0.67 * h),
                control1: CGPoint(x: 0.45 * w, y: 0.58 * h),
                control2: CGPoint(x: 0.47 * w, y: 0.66 * h)
            )

            let rimFill = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [Theme.cyan.opacity(0.95), Theme.blue.opacity(0.55), .clear]),
                startPoint: CGPoint(x: 0.8 * w, y: 0),
                endPoint: CGPoint(x: 0.55 * w, y: 0.7 * h)
            )

            context.drawLayer { layer in
                layer.addFilter(.blur(radius: 9))
                layer.stroke(
                    rim,
                    with: rimFill,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
            }
            context.drawLayer { layer in
                layer.addFilter(.blur(radius: 2.5))
                layer.stroke(
                    rim,
                    with: rimFill,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
            }

            // Deepen the black valley between the two ribbons.
            context.drawLayer { layer in
                layer.addFilter(.blur(radius: 30))
                var hole = Path()
                hole.addEllipse(in: CGRect(x: 0.30 * w, y: 0.28 * h, width: 0.46 * w, height: 0.5 * h))
                layer.fill(hole, with: .color(Color.black.opacity(0.35)))
            }
        }
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: 0.44),
                    .init(color: .clear, location: 0.82),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .scaleEffect(drifting ? 1.035 : 1)
        .offset(y: drifting ? -3 : 3)
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 18).repeatForever(autoreverses: true),
            value: drifting
        )
        .onAppear { drifting = true }
        .accessibilityHidden(true)
    }
}


// MARK: - App mark

/// The in-app icon: a dark squircle, a big emoji face and a thought-bubble tail.
struct AppMark: View {
    var size: CGFloat = 92

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.235, style: .continuous)
                .fill(Color(red: 0.05, green: 0.05, blue: 0.06))

            Circle()
                .fill(Theme.orange.opacity(0.70))
                .frame(width: size * 0.95, height: size * 0.95)
                .offset(x: -size * 0.34, y: -size * 0.28)
                .blur(radius: size * 0.24)

            Circle()
                .fill(Theme.blue.opacity(0.65))
                .frame(width: size * 0.9, height: size * 0.9)
                .offset(x: size * 0.36, y: -size * 0.24)
                .blur(radius: size * 0.24)

            Text("😄")
                .font(.system(size: size * 0.46))
                .offset(x: -size * 0.03, y: -size * 0.035)
                .shadow(color: .black.opacity(0.45), radius: size * 0.08, y: size * 0.04)

            ZStack {
                Circle().frame(width: size * 0.07)
                    .offset(x: size * 0.29, y: size * 0.28)
                Circle().frame(width: size * 0.047)
                    .offset(x: size * 0.35, y: size * 0.35)
                Circle().frame(width: size * 0.032)
                    .offset(x: size * 0.39, y: size * 0.40)
            }
            .foregroundStyle(.white.opacity(0.82))

            RoundedRectangle(cornerRadius: size * 0.235, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.08), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )

            RoundedRectangle(cornerRadius: size * 0.235, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Theme.orange.opacity(0.95), Theme.blue.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.235, style: .continuous))
        .shadow(color: Theme.orange.opacity(0.22), radius: size * 0.34, y: size * 0.14)
        .accessibilityHidden(true)
    }
}

// MARK: - Buttons

struct PillButton: View {
    enum Kind {
        case primary, secondary
    }

    let title: String
    var kind: Kind = .primary
    var compact = false
    let action: () -> Void

    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: compact ? 11.5 : 12.5, weight: .semibold))
                .foregroundStyle(kind == .primary ? .white : Theme.text.opacity(0.85))
                .padding(.horizontal, compact ? 12 : 18)
                .frame(height: compact ? 26 : 33)
                .background(background)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(rim, lineWidth: 1))
                .shadow(color: glow, radius: hovered ? 9 : 5, y: 2)
                .scaleEffect(hovered ? 1.025 : 1)
                .contentShape(Capsule())
        }
        .buttonStyle(PressableStyle())
        .onHover { inside in
            withAnimation(.easeOut(duration: 0.14)) { hovered = inside }
        }
        .accessibilityLabel(title)
    }

    private var background: LinearGradient {
        if kind == .primary {
            return LinearGradient(
                colors: hovered
                    ? [Color(red: 0.31, green: 0.58, blue: 1.0), Color(red: 0.15, green: 0.40, blue: 0.93)]
                    : [Theme.blueBright, Theme.blue],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        return LinearGradient(
            colors: [Color.white.opacity(hovered ? 0.14 : 0.09), Color.white.opacity(hovered ? 0.10 : 0.06)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var rim: Color {
        kind == .primary ? Color.white.opacity(0.20) : Color.white.opacity(0.10)
    }

    private var glow: Color {
        kind == .primary ? Theme.blue.opacity(0.35) : .black.opacity(0.18)
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.snappy(duration: 0.14), value: configuration.isPressed)
    }
}

// MARK: - Small parts

struct PageDots: View {
    let count: Int
    let index: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<count, id: \.self) { dot in
                Capsule()
                    .fill(Color.white.opacity(dot == index ? 0.85 : 0.22))
                    .frame(width: dot == index ? 14 : 4, height: 4)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: index)
        .accessibilityHidden(true)
    }
}

struct GlassCard<Content: View>: View {
    var padding: CGFloat = 14
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
    }
}

struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(Theme.hairline)
            .frame(height: 1)
    }
}

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.7)
            .foregroundStyle(Theme.text3)
    }
}

struct StatusText: View {
    let text: String
    var color: Color = Theme.green
    var icon = "checkmark.circle.fill"

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(color)
        .animation(.easeInOut(duration: 0.25), value: text)
    }
}

struct InfoRow<Trailing: View>: View {
    let icon: String
    let title: String
    var subtitle: String?
    var tint: Color = Theme.blue
    var showsIcon: Bool = true
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 12) {
            if showsIcon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    )
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Theme.text)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 10.5))
                        .foregroundStyle(Theme.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            trailing()
        }
        .padding(.vertical, 10)
    }
}

struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let display: String

    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.text.opacity(0.9))
                Spacer()
                Text(display)
                    .font(.system(size: 10.5, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(Theme.text2)
            }
            Slider(value: $value, in: range)
                .tint(Theme.blue)
                .controlSize(.small)
        }
        .padding(.vertical, 5)
    }
}

struct SkinToneChips: View {
    @Binding var skinIndex: Int

    var body: some View {
        HStack(spacing: 7) {
            ForEach(SkinTone.allCases) { tone in
                Button {
                    withAnimation(.snappy(duration: 0.2)) { skinIndex = tone.rawValue }
                } label: {
                    Text(tone.preview)
                        .font(.system(size: 20))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Color.white.opacity(skinIndex == tone.rawValue ? 0.10 : 0.045))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .strokeBorder(
                                    skinIndex == tone.rawValue ? Theme.blue : Color.white.opacity(0.06),
                                    lineWidth: skinIndex == tone.rawValue ? 1.4 : 1
                                )
                        )
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(tone.title)
                .accessibilityAddTraits(skinIndex == tone.rawValue ? .isSelected : [])
            }
        }
    }
}

struct CountStepper: View {
    @Binding var count: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 8) {
            stepButton("minus") { count = max(range.lowerBound, count - 1) }
            Text("\(count)")
                .font(.system(size: 11.5, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.text)
                .frame(width: 16)
            stepButton("plus") { count = min(range.upperBound, count + 1) }
        }
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 8.5, weight: .bold))
                .foregroundStyle(Theme.text.opacity(0.85))
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.white.opacity(0.07)))
                .overlay(Circle().strokeBorder(Color.white.opacity(0.08)))
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(symbol == "plus" ? "More emoji" : "Fewer emoji")
    }
}
