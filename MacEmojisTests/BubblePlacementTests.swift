import XCTest
@testable import MacEmojis

final class BubblePlacementTests: XCTestCase {
    private let visible = CGRect(x: 0, y: 0, width: 1000, height: 800)
    private let size = CGSize(width: 300, height: 100)
    private let bleed: CGFloat = 14

    func testBubbleSitsAboveTheLineWithGap() {
        let placement = BubblePlacer.place(
            panelSize: size,
            bleed: bleed,
            caret: CGRect(x: 500, y: 300, width: 2, height: 18),
            field: CGRect(x: 400, y: 290, width: 200, height: 30),
            window: nil,
            visible: visible,
            mouse: .zero
        )

        XCTAssertEqual(placement.frame.minY, 312)
        XCTAssertEqual(placement.frame.minY + bleed, 326, "visible bubble bottom stays 8pt above the caret line")
        XCTAssertEqual(placement.frame.minX, 351)
        XCTAssertEqual(placement.tailAnchor, 0.5, accuracy: 0.001)
        XCTAssertFalse(placement.tailOnTop)
    }

    func testBubbleDropsBelowTheFieldWhenTheScreenHasNoRoomAbove() {
        var lowScreen = visible
        lowScreen.size.height = 300

        let placement = BubblePlacer.place(
            panelSize: size,
            bleed: bleed,
            caret: CGRect(x: 500, y: 280, width: 2, height: 18),
            field: CGRect(x: 400, y: 270, width: 200, height: 28),
            window: nil,
            visible: lowScreen,
            mouse: .zero
        )

        XCTAssertEqual(placement.frame.minY, 176)
        XCTAssertTrue(placement.tailOnTop)
    }

    func testCaretBelowFirstLineAnchorsAboveTheWholeField() {
        let placement = BubblePlacer.place(
            panelSize: size,
            bleed: bleed,
            caret: CGRect(x: 500, y: 300, width: 2, height: 18),
            field: CGRect(x: 400, y: 200, width: 200, height: 200),
            window: nil,
            visible: visible,
            mouse: .zero
        )

        XCTAssertEqual(placement.frame.minY, 394, "bubble clears the earlier lines as well as the caret")
        XCTAssertEqual(placement.tailAnchor, 0.5, accuracy: 0.001)
        XCTAssertFalse(placement.tailOnTop)
    }

    func testHorizontalClampKeepsTheTailPointingAtTheCaret() {
        let placement = BubblePlacer.place(
            panelSize: size,
            bleed: bleed,
            caret: CGRect(x: 480, y: 306, width: 2, height: 18),
            field: CGRect(x: 100, y: 300, width: 400, height: 40),
            window: nil,
            visible: visible,
            mouse: .zero
        )

        XCTAssertEqual(placement.frame.minX, 202, "bubble stays inside the wide field, not the caret")
        XCTAssertEqual(placement.tailAnchor, 0.84, accuracy: 0.001, "tail still aims at the caret")
    }

    func testLinesAboveUsesTheCaretHeightAsTheThreshold() {
        let field = CGRect(x: 0, y: 200, width: 400, height: 200)
        XCTAssertTrue(BubblePlacer.hasLinesAbove(CGRect(x: 10, y: 300, width: 2, height: 18), in: field))
        XCTAssertFalse(BubblePlacer.hasLinesAbove(CGRect(x: 10, y: 390, width: 2, height: 18), in: field))
    }
}
