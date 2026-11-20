import XCTest
@testable import MacEmojis

final class AXFrameAlignmentTests: XCTestCase {
    func testChromiumWindowLocalFramesAreShiftedAndCaretDropped() {
        let axWindow = CGRect(x: 0, y: 33, width: 1512, height: 949)
        let cgOrigin = CGPoint(x: -2560, y: -410)
        let field = CGRect(x: 459, y: 39, width: 585, height: 28)
        let caret = CGRect(x: 500, y: 50, width: 0, height: 14)

        let aligned = AXField.alignedFrames(
            field: field,
            caret: caret,
            axWindow: axWindow,
            cgOrigin: cgOrigin
        )

        XCTAssertEqual(aligned.field, CGRect(x: -2101, y: -404, width: 585, height: 28))
        XCTAssertNil(aligned.caret, "Chromium caret bounds are unreliable in the shifted space")
        XCTAssertEqual(aligned.window, CGRect(origin: cgOrigin, size: axWindow.size))
    }

    func testNativeGlobalFramesAreUntouched() {
        let window = CGRect(x: -2251, y: -355, width: 603, height: 505)
        let field = CGRect(x: -2251, y: -255, width: 586, height: 382)
        let caret = CGRect(x: -2175, y: -269, width: 0, height: 14)

        let aligned = AXField.alignedFrames(
            field: field,
            caret: caret,
            axWindow: window,
            cgOrigin: window.origin
        )

        XCTAssertEqual(aligned.field, field)
        XCTAssertEqual(aligned.caret, caret)
        XCTAssertEqual(aligned.window, window)
    }

    func testGlobalWindowWithWindowLocalContentIsShifted() {
        let window = CGRect(x: -1638, y: -102, width: 1280, height: 705)
        let field = CGRect(x: 114, y: 206, width: 1108, height: 73)

        let aligned = AXField.alignedFrames(
            field: field,
            caret: CGRect(x: 120, y: 210, width: 0, height: 14),
            axWindow: window,
            cgOrigin: window.origin
        )

        XCTAssertEqual(aligned.field, CGRect(x: -1524, y: 104, width: 1108, height: 73))
        XCTAssertNil(aligned.caret)
        XCTAssertEqual(aligned.window, window)
    }
}
