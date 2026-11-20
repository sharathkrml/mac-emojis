import XCTest
@testable import MacEmojis

final class SentenceTests: XCTestCase {
    func testSentenceModeUsesTextAfterLastTerminator() {
        let context = Sentence.context(
            value: "I went out. Buy a cake",
            caret: 22,
            replaceEnabled: true,
            sentenceEnabled: true
        )
        XCTAssertEqual(context, .sentence(text: "Buy a cake", caret: 22))
    }

    func testCaretInsideWordUsesTextBeforeCaret() {
        let context = Sentence.context(
            value: "i want a cake",
            caret: 13,
            replaceEnabled: true,
            sentenceEnabled: true
        )
        XCTAssertEqual(context, .sentence(text: "i want a cake", caret: 13))
    }

    func testColonTokenIsReplaceMode() {
        let context = Sentence.context(
            value: "Lunch with Sarah :heart",
            caret: 23,
            replaceEnabled: true,
            sentenceEnabled: true
        )
        XCTAssertEqual(context, .replace(word: "heart", tokenRange: NSRange(location: 17, length: 6)))
    }

    func testColonTokenBeatsSentenceMode() {
        let context = Sentence.context(
            value: "I want cake :cake",
            caret: 17,
            replaceEnabled: true,
            sentenceEnabled: true
        )
        XCTAssertEqual(context, .replace(word: "cake", tokenRange: NSRange(location: 12, length: 5)))
    }

    func testColonAfterSpaceAndPunctuation() {
        let context = Sentence.context(
            value: "hi!:party",
            caret: 9,
            replaceEnabled: true,
            sentenceEnabled: true
        )
        XCTAssertEqual(context, .replace(word: "party", tokenRange: NSRange(location: 3, length: 6)))
    }

    func testTimeIsNotAToken() {
        let context = Sentence.context(
            value: "Lunch at 12:30",
            caret: 14,
            replaceEnabled: true,
            sentenceEnabled: true
        )
        XCTAssertEqual(context, .sentence(text: "Lunch at 12:30", caret: 14))
    }

    func testLetterBeforeColonIsNotAToken() {
        let context = Sentence.context(
            value: "i:heart",
            caret: 7,
            replaceEnabled: true,
            sentenceEnabled: true
        )
        XCTAssertEqual(context, .sentence(text: "i:heart", caret: 7))
    }

    func testTokenOverTwentyCharactersIsNotAToken() {
        let context = Sentence.context(
            value: ":abcdefghijklmnopqrstu",
            caret: 22,
            replaceEnabled: true,
            sentenceEnabled: true
        )
        XCTAssertEqual(context, .sentence(text: ":abcdefghijklmnopqrstu", caret: 22))
    }

    func testSpaceCancelsToken() {
        let context = Sentence.context(
            value: ":heart ",
            caret: 7,
            replaceEnabled: true,
            sentenceEnabled: true
        )
        XCTAssertEqual(context, .sentence(text: ":heart", caret: 7))
    }

    func testModesRespectToggles() {
        XCTAssertNil(Sentence.context(value: "hello", caret: 5, replaceEnabled: false, sentenceEnabled: false))
        XCTAssertNil(Sentence.context(value: ":heart", caret: 6, replaceEnabled: false, sentenceEnabled: false))
        XCTAssertNil(Sentence.context(value: "   ", caret: 3, replaceEnabled: true, sentenceEnabled: true))
    }

    func testSentenceIsCappedAt150Characters() {
        let long = String(repeating: "a", count: 200)
        let context = Sentence.context(value: long, caret: 200, replaceEnabled: true, sentenceEnabled: true)
        guard case .sentence(let text, _)? = context else { return XCTFail("expected sentence mode") }
        XCTAssertEqual(text.count, 150)
    }

    func testNewlineStartsANewSentence() {
        let context = Sentence.context(
            value: "First line\nsecond line",
            caret: 22,
            replaceEnabled: true,
            sentenceEnabled: true
        )
        XCTAssertEqual(context, .sentence(text: "second line", caret: 22))
    }

    // MARK: - Selection suggest

    func testSelectedWordsAreSelectionContext() {
        let context = Sentence.selectionContext(
            value: "i want a cake today",
            selection: NSRange(location: 7, length: 7),
            enabled: true
        )
        XCTAssertEqual(context, .selection(text: "a cake", range: NSRange(location: 7, length: 7)))
    }

    func testSelectionDisabledReturnsNil() {
        XCTAssertNil(Sentence.selectionContext(
            value: "a cake", selection: NSRange(location: 0, length: 6), enabled: false
        ))
    }

    func testWhitespaceOnlySelectionReturnsNil() {
        XCTAssertNil(Sentence.selectionContext(
            value: "a   b", selection: NSRange(location: 1, length: 3), enabled: true
        ))
    }

    func testSelectionBeyondValueReturnsNil() {
        XCTAssertNil(Sentence.selectionContext(
            value: "abc", selection: NSRange(location: 2, length: 5), enabled: true
        ))
    }

    func testSelectionIsCappedAt150Characters() {
        let value = String(repeating: "a", count: 200)
        let context = Sentence.selectionContext(
            value: value, selection: NSRange(location: 0, length: 200), enabled: true
        )
        guard case .selection(let text, _)? = context else { return XCTFail("expected selection mode") }
        XCTAssertEqual(text.count, 150)
    }

    // MARK: - Insertion spacing

    func testSpaceIsAddedAfterNonWhitespace() {
        XCTAssertEqual(Inserter.composedText(emoji: "🎂", caret: 13, charBefore: "e"), " 🎂")
    }

    func testNoSpaceAfterWhitespaceOrAtStart() {
        XCTAssertEqual(Inserter.composedText(emoji: "🎂", caret: 13, charBefore: " "), "🎂")
        XCTAssertEqual(Inserter.composedText(emoji: "🎂", caret: 0, charBefore: nil), "🎂")
    }
}
