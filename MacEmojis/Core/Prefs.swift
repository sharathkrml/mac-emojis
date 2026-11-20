import Foundation

enum Prefs {
    static let enabledKey = "enabled"
    static let sentenceKey = "sentenceSuggest"
    static let replaceKey = "replaceMode"
    static let pauseKey = "pauseSeconds"
    static let countKey = "suggestionCount"
    static let opacityKey = "bubbleOpacity"
    static let skinKey = "skinToneIndex"
    static let onboardedKey = "onboarded"

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            enabledKey: true,
            sentenceKey: true,
            replaceKey: true,
            pauseKey: 0.8,
            countKey: 5,
            opacityKey: 0.95,
            skinKey: 0,
            onboardedKey: false,
        ])
    }

    static var enabled: Bool { UserDefaults.standard.bool(forKey: enabledKey) }
    static var sentenceEnabled: Bool { UserDefaults.standard.bool(forKey: sentenceKey) }
    static var replaceEnabled: Bool { UserDefaults.standard.bool(forKey: replaceKey) }

    static var pause: TimeInterval {
        max(0.3, UserDefaults.standard.double(forKey: pauseKey))
    }

    static var count: Int {
        min(8, max(1, UserDefaults.standard.integer(forKey: countKey)))
    }

    static var opacity: Double {
        let value = UserDefaults.standard.double(forKey: opacityKey)
        return value > 0 ? value : 0.95
    }
}
