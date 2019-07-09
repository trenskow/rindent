import XCTest
@testable import rindent

final class rindentTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(rindent().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
