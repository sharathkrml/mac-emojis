import Foundation

enum SuggestionContext: Equatable {
    case sentence(text: String, caret: Int)
    case replace(word: String, tokenRange: NSRange)
}

enum Sentence {
    static let maxLength = 150

    static func context(
        value: String,
        caret: Int,
        replaceEnabled: Bool,
        sentenceEnabled: Bool
    ) -> SuggestionContext? {
        let ns = value as NSString
        guard caret >= 0, caret <= ns.length else { return nil }
        let prefix = ns.substring(to: caret)

        if replaceEnabled, let token = trailingToken(in: prefix) {
            return .replace(word: token.word, tokenRange: NSRange(location: token.start, length: token.length))
        }

        guard sentenceEnabled else { return nil }
        let slice = sentenceSlice(prefix).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !slice.isEmpty, slice.rangeOfCharacter(from: .alphanumerics) != nil else { return nil }
        return .sentence(text: String(slice.suffix(maxLength)), caret: caret)
    }

    /// `:word` directly before the caret. The colon must not follow a letter or digit, so `12:30` stays plain text.
    static func trailingToken(in prefix: String) -> (word: String, start: Int, length: Int)? {
        guard let regex = try? NSRegularExpression(pattern: "(?<![A-Za-z0-9]):([A-Za-z0-9_+\\-]{1,20})$") else {
            return nil
        }
        let ns = prefix as NSString
        let range = NSRange(location: 0, length: ns.length)
        guard let match = regex.firstMatch(in: prefix, range: range) else { return nil }
        return (ns.substring(with: match.range(at: 1)), match.range.location, match.range.length)
    }

    static func sentenceSlice(_ prefix: String) -> String {
        let terminators: Set<Character> = [".", "?", "!", "\n", "。", "？", "！"]
        guard let index = prefix.lastIndex(where: { terminators.contains($0) }) else { return prefix }
        return String(prefix[prefix.index(after: index)...])
    }
}
