import SwiftUI
import AppKit
import ApplicationServices
import Combine
import ServiceManagement

struct MainView: View {
    @EnvironmentObject private var emo: EmoService

    @AppStorage(Prefs.enabledKey) private var enabled = true
    @AppStorage(Prefs.sentenceKey) private var sentenceSuggest = true
    @AppStorage(Prefs.replaceKey) private var replaceMode = true
    @AppStorage(Prefs.selectionKey) private var selectionSuggest = false
    @AppStorage(Prefs.pauseKey) private var pause = 0.8
    @AppStorage(Prefs.countKey) private var count = 5
    @AppStorage(Prefs.opacityKey) private var opacity = 0.95
    @AppStorage(Prefs.skinKey) private var skinIndex = 0
    @AppStorage(Prefs.onboardedKey) private var onboarded = false

    var onClose: (() -> Void)?

    @State private var trusted = AXField.isTrusted()
    @State private var testText = "i want a cake"
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    private let permissionTick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let size = CGSize(width: 560, height: 700)

    private var selectedTone: SkinTone {
        SkinTone(rawValue: skinIndex) ?? .natural
    }

    var body: some View {
        PanelChrome(size: size, auroraHeight: 300, auroraOpacity: 0.72, onClose: close) {
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 16) {
                        accessibilityBlock
                        modelBlock
                        suggestionsBlock
                        skinBlock
                        testBlock
                    }
                    .padding(.horizontal, 26)
                    .padding(.top, 4)
                    .padding(.bottom, 22)
                }
                .scrollIndicators(.never)
                footer
            }
        }
        .onReceive(permissionTick) { _ in
            trusted = AXField.isTrusted()
            emo.refresh()
        }
        .onExitCommand(perform: close)
    }

    private var header: some View {
        HStack(spacing: 12) {
            AppMark(size: 46)
            VStack(alignment: .leading, spacing: 2) {
                Text("MacEmojis")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.text)
                Text(enabled ? "Suggestions are on" : "Suggestions are paused")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.text2)
                    .animation(.easeInOut(duration: 0.2), value: enabled)
            }
            Spacer()
            Toggle("", isOn: $enabled)
                .toggleStyle(.switch)
                .tint(Theme.blue)
                .controlSize(.small)
                .labelsHidden()
                .accessibilityLabel("Enable suggestions")
        }
        .padding(.horizontal, 26)
        .padding(.top, 34)
        .padding(.bottom, 16)
    }

    private var accessibilityBlock: some View {
        block("Permissions") {
            GlassCard(padding: 14) {
                VStack(spacing: 0) {
                    InfoRow(
                        icon: "accessibility",
                        title: "Accessibility",
                        subtitle: trusted
                            ? "Access granted. The bubble can read the focused field."
                            : "MacEmojis reads the text field you are typing in. Everything stays on this Mac.",
                        tint: trusted ? Theme.green : Theme.orange
                    ) {
                        if trusted {
                            StatusText(text: "Granted")
                        } else {
                            HStack(spacing: 7) {
                                PillButton(title: "Grant Access…", compact: true) {
                                    AXField.promptForAccess()
                                }
                                PillButton(title: "Check Again", kind: .secondary, compact: true) {
                                    trusted = AXField.isTrusted()
                                }
                            }
                        }
                    }

                    if !trusted {
                        Hairline()
                        Text("Already switched on but still not working? Remove MacEmojis from the Accessibility list with “−”, then add this build again.")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.text3)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 10)
                    }
                }
            }
        }
    }

    private var modelBlock: some View {
        block("Emoji model") {
            GlassCard(padding: 14) {
                VStack(spacing: 0) {
                    InfoRow(
                        icon: "sparkles",
                        title: "Emo",
                        subtitle: emo.downloaded
                            ? "5 MB, on device. Works offline."
                            : "A 5 MB on-device model. It downloads once, then works offline.",
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
                            PillButton(title: "Download Model", compact: true) {
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
        }
    }

    private var suggestionsBlock: some View {
        block("Suggestions") {
            GlassCard(padding: 14) {
                VStack(spacing: 0) {
                    toggleRow("Suggest while typing", isOn: $sentenceSuggest)
                    toggleRow("Replace :colon tokens", isOn: $replaceMode)
                    toggleRow("Suggest for selected text", isOn: $selectionSuggest)
                    Hairline().padding(.vertical, 7)
                    SliderRow(
                        title: "Pause before showing",
                        value: $pause,
                        range: 0.3...2,
                        display: String(format: "%.1fs", pause)
                    )
                    SliderRow(
                        title: "Bubble opacity",
                        value: $opacity,
                        range: 0.4...1,
                        display: "\(Int(opacity * 100))%"
                    )
                    HStack {
                        Text("Emoji per bubble")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.text.opacity(0.9))
                        Spacer()
                        CountStepper(count: $count, range: 3...8)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private var skinBlock: some View {
        block("Skin tone") {
            GlassCard(padding: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Applied to every suggestion that supports tone.")
                            .font(.system(size: 10.5))
                            .foregroundStyle(Theme.text2)
                        Spacer()
                        Text(selectedTone.title)
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundStyle(Theme.text)
                            .animation(.easeInOut(duration: 0.2), value: skinIndex)
                    }
                    SkinToneChips(skinIndex: $skinIndex)
                }
            }
        }
    }

    private var testBlock: some View {
        block("Try it") {
            GlassCard(padding: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Type here and pause. This field works even before Accessibility is granted.")
                        .font(.system(size: 10.5))
                        .foregroundStyle(Theme.text2)
                        .fixedSize(horizontal: false, vertical: true)
                    TextEditor(text: $testText)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.text)
                        .tint(Theme.blue)
                        .scrollContentBackground(.hidden)
                        .accessibilityLabel("Try a sentence")
                        .padding(8)
                        .frame(height: 78)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.black.opacity(0.32))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Theme.hairline, lineWidth: 1)
                        )
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Toggle("Launch at login", isOn: $launchAtLogin)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .tint(Theme.blue)
                .font(.system(size: 11))
                .foregroundStyle(Theme.text2)
                .onChange(of: launchAtLogin) { _, newValue in
                    setLaunchAtLogin(newValue)
                }
            Spacer()
            PillButton(title: "Done") {
                UserDefaults.standard.set(true, forKey: Prefs.onboardedKey)
                close()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 26)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .background(
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.25)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func block<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            SectionLabel(text: title)
            content()
        }
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(Theme.text.opacity(0.9))
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .tint(Theme.blue)
                .controlSize(.small)
                .labelsHidden()
                .accessibilityLabel(title)
        }
        .padding(.vertical, 4)
    }

    private func close() {
        if let onClose {
            onClose()
        } else {
            NSApp.keyWindow?.close()
        }
    }

    private func setLaunchAtLogin(_ wantsLogin: Bool) {
        do {
            if wantsLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
