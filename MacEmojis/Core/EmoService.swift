import Foundation
import Emo

enum SkinTone: Int, CaseIterable, Identifiable {
    case natural, light, mediumLight, medium, mediumDark, dark

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .natural: "Default"
        case .light: "Light"
        case .mediumLight: "Medium light"
        case .medium: "Medium"
        case .mediumDark: "Medium dark"
        case .dark: "Dark"
        }
    }

    var preview: String {
        switch self {
        case .natural: "👍"
        case .light: "👍🏻"
        case .mediumLight: "👍🏼"
        case .medium: "👍🏽"
        case .mediumDark: "👍🏾"
        case .dark: "👍🏿"
        }
    }

    var tone: EmojiSkinTone {
        switch self {
        case .natural: .default
        case .light: .light
        case .mediumLight: .mediumLight
        case .medium: .medium
        case .mediumDark: .mediumDark
        case .dark: .dark
        }
    }
}

@MainActor
final class EmoService: ObservableObject {
    static let shared = EmoService()

    private let emo = Emo()

    @Published private(set) var downloaded = false
    @Published private(set) var progress: Double?
    @Published private(set) var errorText: String?

    init() {
        downloaded = emo.isDownloaded()
    }

    var selectedSkinTone: EmojiSkinTone {
        (SkinTone(rawValue: UserDefaults.standard.integer(forKey: Prefs.skinKey)) ?? .natural).tone
    }

    func refresh() {
        guard progress == nil else { return }
        downloaded = emo.isDownloaded()
    }

    func suggestions(for text: String) async -> [String] {
        do {
            let results = try await emo.suggestions(for: text, limit: Prefs.count, skinTone: selectedSkinTone)
            return results.map(\.emoji)
        } catch {
            return []
        }
    }

    func downloadModel() async {
        guard progress == nil else { return }
        progress = 0
        errorText = nil
        do {
            try await emo.download { fraction in
                Task { @MainActor [weak self] in
                    self?.progress = fraction
                }
            }
            downloaded = true
        } catch {
            errorText = error.localizedDescription
        }
        progress = nil
    }
}
