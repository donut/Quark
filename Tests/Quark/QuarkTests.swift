import XCTest
@testable import Quark

class QuarkTests : XCTestCase {
    func testExample() {
        XCTAssertEqual(2 + 2, 4)
    }
}

extension QuarkTests {
    static var allTests : [(String, (QuarkTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
