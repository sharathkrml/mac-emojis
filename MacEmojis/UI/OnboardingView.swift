import SwiftUI
import Combine

/// First-run flow: welcome, setup, live demo, personalization.
struct OnboardingView: View {
    @EnvironmentObject private var emo: EmoService
    @AppStorage(Prefs.onboardedKey) private var onboarded = false
    @AppStorage(Prefs.skinKey) private var skinIndex = 0
    @AppStorage(Prefs.countKey) private var count = 5
    @AppStorage(Prefs.opacityKey) private var opacity = 0.95
    @AppStorage(Prefs.pauseKey) private var pause = 0.8

    let onFinish: () -> Void
    let onClose: () -> Void

    @State private var page = 0
    @State private var direction = 1
    @State private var trusted = AXField.isTrusted()
    @State private var demoText = "happy birthday"
    @State private var demoEmoji = ["🎂", "🎉", "🎈", "😊", "❤️"]
    @State private var skipDemoFetch = false
    @FocusState private var demoFocused: Bool

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let sampleEmoji = ["🎂", "🎉", "🎈", "😊", "❤️"]

    var body: some View {
        PanelChrome(size: CGSize(width: 520, height: 600), auroraHeight: 390, onClose: onClose) {
            VStack(spacing: 0) {
                pageArea
                footer
            }
        }
        .onReceive(tick) { _ in
            trusted = AXField.isTrusted()
            emo.refresh()
        }
        .onExitCommand(perform: onClose)
        .onExitCommand(perform: onClose)
    }

    private var pageArea: some View {
        ZStack {
            pageContent
                .id(page)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: direction > 0 ? .trailing : .leading).combined(with: .opacity),
                        removal: .move(edge: direction > 0 ? .leading : .trailing).combined(with: .opacity)
                    )
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    @ViewBuilder
    private var pageContent: some View {
        switch page {
        case 0: WelcomePage()
        case 1: setupPage
        case 2: demoPage
        default: looksPage
        }
    }

    // MARK: - Setup

    private var setupPage: some View {
        pageScaffold(
            title: "One permission, one download",
            subtitle: "The bubble follows you into any app. Nothing leaves this Mac."
        ) {
            GlassCard(padding: 14) {
                VStack(spacing: 0) {
                    InfoRow(
                        icon: "accessibility",
                        title: "Accessibility",
                        subtitle: trusted
                            ? "Access granted. The bubble can see the field you are in."
                            : "Lets the bubble read what you are typing, wherever you type.",
                        tint: trusted ? Theme.green : Theme.orange
                    ) {
                        if trusted {
                            StatusText(text: "Granted")
                        } else {
                            PillButton(title: "Grant", compact: true) {
                                AXField.promptForAccess()
                            }
                        }
                    }

                    Hairline()

                    InfoRow(
                        icon: "sparkles",
                        title: "Emoji model",
                        subtitle: emo.downloaded
                            ? "5 MB, downloaded once. Ranks emoji offline."
                            : "A 5 MB on-device model. Downloads once, then works offline.",
                        tint: emo.downloaded ? Theme.green : Theme.blue
                    ) {
                        if emo.downloaded {
                            StatusText(text: "Ready")
                        } else if let progress = emo.progress {
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 11, weight: .semibold))
                                .monospacedDigit()
                                .foregroundStyle(Theme.text2)
                        } else {
                            PillButton(title: "Download", compact: true) {
                                Task { await emo.downloadModel() }
                            }
                        }
                    }

                    if let progress = emo.progress {
                        ProgressView(value: progress)
                            .tint(Theme.blue)
                            .controlSize(.small)
                            .padding(.bottom, 8)
                    }

                    if let error = emo.errorText {
                        Text(error)
                            .font(.system(size: 10))
                            .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.38))
                            .padding(.top, 4)
                    }
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 8.5))
                Text("Read on this Mac. Never sent anywhere.")
            }
            .font(.system(size: 10.5))
            .foregroundStyle(Theme.text3)
            .padding(.top, 14)
        }
    }

    // MARK: - Live demo

    private var demoPage: some View {
        pageScaffold(
            title: "Emoji that fit the moment",
            subtitle: "Pause while typing and the bubble appears above the line, never over your words."
        ) {
            GlassCard(padding: 18) {
                VStack(spacing: 0) {
                    DemoBubble(emojis: demoEmoji) { emoji in
                        skipDemoFetch = true
                        withAnimation(.snappy(duration: 0.2)) { demoText += emoji }
                    }
                    .id(demoEmoji.joined(separator: ","))
                    .frame(maxWidth: .infinity, alignment: .center)

                    HStack(spacing: 3) {
                        Circle().frame(width: 4, height: 4)
                        Circle().frame(width: 3, height: 3)
                        Circle().frame(width: 2, height: 2)
                    }
                    .foregroundStyle(.white.opacity(0.28))
                    .padding(.vertical, 7)

                    TextField("", text: $demoText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14.5))
                        .foregroundStyle(Theme.text)
                        .tint(Theme.blue)
                        .focused($demoFocused)
                        .accessibilityLabel("Try a sentence")
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Color.black.opacity(0.35))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .strokeBorder(demoFocused ? Theme.blue.opacity(0.55) : Theme.hairline, lineWidth: 1)
                        )
                        .animation(.easeOut(duration: 0.2), value: demoFocused)
                        .onSubmit { demoFocused = true }
                }
            }

            Text(emo.downloaded ? "Type a line, or click an emoji to drop it in." : "Showing samples until the Emo model is downloaded.")
                .font(.system(size: 10.5))
                .foregroundStyle(Theme.text3)
                .padding(.top, 12)
        }
        .task(id: demoText) {
            if skipDemoFetch {
                skipDemoFetch = false
                return
            }
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !Task.isCancelled else { return }
            await loadDemo()
        }
    }

    private func loadDemo() async {
        let text = demoText.trimmingCharacters(in: .whitespacesAndNewlines)
        var values: [String] = []
        if emo.downloaded {
            values = await emo.suggestions(for: text).map(\.emoji)
        }
        if values.isEmpty {
            values = sampleEmoji
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            demoEmoji = Array(values.prefix(5))
        }
    }

    // MARK: - Personalization

    private var looksPage: some View {
        pageScaffold(
            title: "Make it yours",
            subtitle: "A tone that matches you, and a bubble that fits your flow."
        ) {
            GlassCard(padding: 14) {
                VStack(alignment: .leading, spacing: 11) {
                    HStack {
                        Text("Skin tone")
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(Theme.text)
                        Spacer()
                        Text(selectedTone.title)
                            .font(.system(size: 10.5))
                            .foregroundStyle(Theme.text2)
                    }
                    SkinToneChips(skinIndex: $skinIndex)
                    Text("Emo applies it to every suggestion that supports tone.")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.text3)
                }
            }

            GlassCard(padding: 14) {
                VStack(spacing: 2) {
                    HStack {
                        Text("Emoji per bubble")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.text.opacity(0.9))
                        Spacer()
                        CountStepper(count: $count, range: 3...8)
                    }
                    .padding(.vertical, 4)

                    Hairline().padding(.vertical, 5)

                    SliderRow(
                        title: "Pause before showing",
                        value: $pause,
                        range: 0.3...2,
                        display: String(format: "%.1fs", pause)
                    )

                    Hairline().padding(.vertical, 5)

                    SliderRow(
                        title: "Bubble opacity",
                        value: $opacity,
                        range: 0.4...1,
                        display: "\(Int(opacity * 100))%"
                    )
                }
            }
            .padding(.top, 12)
        }
    }

    // MARK: - Page chrome

    private func pageScaffold<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            VStack(spacing: 7) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.text)
                Text(subtitle)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.text2)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(width: 400)
            }
            content()
                .padding(.top, 22)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 34)
        .padding(.top, 42)
        .padding(.bottom, 8)
    }

    private var footer: some View {
        ZStack {
            if page == 0 {
                PillButton(title: "Get Started") { go(1) }
            } else {
                HStack {
                    PillButton(title: "Back", kind: .secondary) { go(-1) }
                    Spacer()
                    PillButton(title: page == 3 ? "Start Typing" : "Continue") {
                        page == 3 ? finish() : go(1)
                    }
                }
                PageDots(count: 4, index: page)
            }
        }
        .padding(.horizontal, 30)
        .padding(.top, 14)
        .padding(.bottom, 24)
    }

    private var selectedTone: SkinTone {
        SkinTone(rawValue: skinIndex) ?? .natural
    }

    private func go(_ delta: Int) {
        let target = page + delta
        guard (0..<4).contains(target) else { return }
        direction = delta
        withAnimation(.spring(response: 0.52, dampingFraction: 0.9)) {
            page = target
        }
    }

    private func finish() {
        onboarded = true
        onFinish()
    }
}

// MARK: - Welcome

private struct WelcomePage: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var entered = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            AppMark(size: 94)
                .scaleEffect(entered ? 1 : 0.9)
                .opacity(entered ? 1 : 0)
                .animation(
                    reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.8).delay(0.08),
                    value: entered
                )

            Text("Welcome to MacEmojis")
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(Theme.text)
                .padding(.top, 24)
                .offset(y: entered ? 0 : 8)
                .opacity(entered ? 1 : 0)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.45).delay(0.22), value: entered)

            Text("The emoji you meant, right where you are typing. On\u{00A0}device, in any app.")
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.text2)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .frame(width: 330)
                .padding(.top, 9)
                .offset(y: entered ? 0 : 8)
                .opacity(entered ? 1 : 0)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.45).delay(0.32), value: entered)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 34)
        .padding(.top, 34)
        .onAppear { entered = true }
    }
}

// MARK: - Demo bubble

private struct DemoBubble: View {
    let emojis: [String]
    let onPick: (String) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(emojis.enumerated()), id: \.offset) { index, emoji in
                DemoChip(emoji: emoji, index: index) { onPick(emoji) }
            }
        }
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color.white.opacity(0.075))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.32), radius: 10, y: 5)
    }

    private struct DemoChip: View {
        let emoji: String
        let index: Int
        let action: () -> Void

        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @State private var appeared = false
        @State private var hovered = false

        var body: some View {
            Button(action: action) {
                Text(emoji)
                    .font(.system(size: 22))
                    .frame(width: 37, height: 37)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(hovered ? 0.10 : 0.045))
                    )
                    .scaleEffect(hovered ? 1.15 : 1)
                    .scaleEffect(appeared ? 1 : 0.8)
                    .offset(y: appeared ? 0 : 6)
                    .opacity(appeared ? 1 : 0)
            }
            .buttonStyle(.plain)
            .onHover { inside in
                withAnimation(.snappy(duration: 0.16)) { hovered = inside }
            }
            .onAppear {
                guard !reduceMotion else {
                    appeared = true
                    return
                }
                withAnimation(.spring(response: 0.38, dampingFraction: 0.72).delay(Double(index) * 0.05)) {
                    appeared = true
                }
            }
            .accessibilityLabel("Insert \(emoji)")
        }
    }
}
