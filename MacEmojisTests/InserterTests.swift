import XCTest
@testable import MacEmojis

final class InserterTests: XCTestCase {
    func testAtStartDoesNotAddSpace() {
        XCTAssertEqual(
            Inserter.composedText(emoji: "🎂", caret: 0, charBefore: nil),
            "🎂"
        )
    }

    func testAfterWordAddsSpace() {
        XCTAssertEqual(
            Inserter.composedText(emoji: "🎂", caret: 5, charBefore: "e"),
            " 🎂"
        )
    }

    func testAfterWhitespaceDoesNotAddSpace() {
        XCTAssertEqual(
            Inserter.composedText(emoji: "🎂", caret: 5, charBefore: " "),
            "🎂"
        )
        XCTAssertEqual(
            Inserter.composedText(emoji: "🎂", caret: 5, charBefore: "\n"),
            "🎂"
        )
    }

    func testMissingCharacterDoesNotAddSpace() {
        XCTAssertEqual(
            Inserter.composedText(emoji: "🎂", caret: 5, charBefore: nil),
            "🎂"
        )
    }
}
