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
    @AppStorage(Prefs.pauseKey) private var pause = 0.8
    @AppStorage(Prefs.countKey) private var count = 5
    @AppStorage(Prefs.opacityKey) private var opacity = 0.95
    @AppStorage(Prefs.skinKey) private var skinIndex = 0
    @AppStorage(Prefs.onboardedKey) private var onboarded = false

    @State private var trusted = AXField.isTrusted()
    @State private var testText = "i want a cake"
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    private let permissionTick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var selectedTone: SkinTone {
        SkinTone(rawValue: skinIndex) ?? .natural
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                permissionSection
                modelSection
                behaviorSection
                skinSection
                testSection
                footer
            }
            .padding(22)
        }
        .frame(width: 480, height: 680)
        .onReceive(permissionTick) { _ in
            trusted = AXField.isTrusted()
            emo.refresh()
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("MacEmojis").font(.system(size: 22, weight: .semibold))
                Text("Emoji suggestions anywhere you type.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $enabled)
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }

    private var permissionSection: some View {
        section("Accessibility") {
            HStack(spacing: 8) {
                Circle()
                    .fill(trusted ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(trusted ? "Access granted" : "Access needed")
                Spacer()
            }
            if !trusted {
                Text("MacEmojis reads the text field you are typing in. Everything stays on this Mac.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    Button("Grant Access…") { AXField.promptForAccess() }
                    Button("Check Again") { trusted = AXField.isTrusted() }
                }
                Text("Already switched on but still red? Remove MacEmojis from the Accessibility list with “−”, then add the current build again.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var modelSection: some View {
        section("Emoji model") {
            if emo.downloaded {
                Label("Ready · 5 MB · on device", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if let progress = emo.progress {
                ProgressView(value: progress) {
                    Text("Downloading model… \(Int(progress * 100))%")
                        .font(.callout)
                }
            } else {
                Text("Emo is a 5 MB on-device model. It downloads once, then works offline.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button("Download Model") {
                    Task { await emo.downloadModel() }
                }
            }
            if let error = emo.errorText {
                Text(error).font(.caption).foregroundStyle(.red)
            }
        }
    }

    private var behaviorSection: some View {
        section("Suggestions") {
            Toggle("Suggest while typing", isOn: $sentenceSuggest)
            HStack(spacing: 10) {
                Text("Pause before showing").frame(width: 150, alignment: .leading)
                Slider(value: $pause, in: 0.3...2, step: 0.1)
                Text(String(format: "%.1fs", pause))
                    .monospacedDigit()
                    .frame(width: 42, alignment: .trailing)
            }
            Toggle("Replace :colon tokens", isOn: $replaceMode)
            Stepper("Emoji per bubble: \(count)", value: $count, in: 3...8)
            HStack(spacing: 10) {
                Text("Bubble opacity").frame(width: 150, alignment: .leading)
                Slider(value: $opacity, in: 0.4...1)
                Text("\(Int(opacity * 100))%")
                    .monospacedDigit()
                    .frame(width: 42, alignment: .trailing)
            }
        }
    }

    private var skinSection: some View {
        section("Skin tone") {
            HStack(spacing: 12) {
                Picker("Skin tone", selection: $skinIndex) {
                    ForEach(SkinTone.allCases) { tone in
                        Text(tone.title).tag(tone.rawValue)
                    }
                }
                .labelsHidden()
                .frame(width: 180)
                Text(selectedTone.preview).font(.system(size: 26))
                Spacer()
            }
        }
    }

    private var testSection: some View {
        section("Try it") {
            Text("Type here and pause. This field works even before Accessibility is granted.")
                .font(.callout)
                .foregroundStyle(.secondary)
            TextEditor(text: $testText)
                .font(.system(size: 15))
                .frame(height: 80)
                .padding(6)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(.quaternary)
                }
        }
    }

    private var footer: some View {
        HStack {
            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    setLaunchAtLogin(newValue)
                }
            Spacer()
            Button("Done") {
                UserDefaults.standard.set(true, forKey: Prefs.onboardedKey)
                NSApp.keyWindow?.performClose(nil)
            }
            .keyboardShortcut(.defaultAction)
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content()
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
