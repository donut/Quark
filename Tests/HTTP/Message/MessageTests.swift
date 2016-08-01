import XCTest
@testable import Quark

class MessageTests : XCTestCase {
    func testHeadersCaseInsensitivity() {
        let headers: Headers = [
            "Content-Type": "application/json",
        ]
        XCTAssertEqual(headers["content-TYPE"], "application/json")
    }

    func testHeadersDescription() {
        let headers: Headers = [
            "Content-Type": "application/json",
        ]
        XCTAssertEqual(String(headers), "Content-Type: application/json\n")
    }

    func testHeadersEquality() {
        let headers: Headers = [
            "Content-Type": "application/json",
        ]
        XCTAssertEqual(headers, headers)
    }

    func testContentType() {
        let mediaType = MediaType(type: "application", subtype: "json")
        var request = Request(headers: ["Content-Type": "application/json"])
        XCTAssertEqual(request.contentType, mediaType)
        request.contentType = mediaType
        XCTAssertEqual(request.headers["Content-Type"], "application/json")
    }

    func testContentLength() {
        var request = Request()
        XCTAssertEqual(request.contentLength, 0)
        request.contentLength = 420
        XCTAssertEqual(request.headers["Content-Length"], "420")
    }

    func testTransferEncoding() {
        var request = Request(headers: ["Transfer-Encoding": "foo"])
        XCTAssertEqual(request.transferEncoding, "foo")
        request.transferEncoding = "chunked"
        XCTAssertTrue(request.isChunkEncoded)
    }
}

extension MessageTests {
    static var allTests: [(String, (MessageTests) -> () throws -> Void)] {
        return [
            ("testHeadersCaseInsensitivity", testHeadersCaseInsensitivity),
            ("testContentType", testContentType),
        ]
    }
}
