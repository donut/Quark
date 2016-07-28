import XCTest
@testable import Quark

class ContentNegotiationMiddlewareTests : XCTestCase {
    let contentNegotiation = ContentNegotiationMiddleware(mediaTypes: [JSON.self, URLEncodedForm.self])

    func testJSONRequestResponse() throws {
        let request = Request(
            headers: [
                "Content-Type": "application/json; charset=utf-8"
            ],
            body: "{\"foo\":\"bar\"}"
        )

        let responder = BasicResponder { request in
            XCTAssertEqual(request.content, ["foo": "bar"])
            return try Response(content: ["fuu": "baz"])
        }

        let response = try contentNegotiation.respond(to: request, chainingTo: responder)

        XCTAssertEqual(response.headers["Content-Type"], "application/json; charset=utf-8")
        XCTAssertEqual(response.body, .buffer("{\"fuu\":\"baz\"}"))
    }

    func testURLEncodedFormRequestDefaultJSONResponse() throws {
        let request = Request(
            headers: [
                "Content-Type": "application/x-www-form-urlencoded; charset=utf-8"
            ],
            body: "foo=bar"
        )

        let responder = BasicResponder { request in
            XCTAssertEqual(request.content, ["foo": "bar"])
            return try Response(content: ["fuu": "baz"])
        }

        let response = try contentNegotiation.respond(to: request, chainingTo: responder)

        // Because there was no Accept header we serializer with the first media type in the
        // content negotiation middleware media type list. In this case JSON.
        XCTAssertEqual(response.headers["Content-Type"], "application/json; charset=utf-8")
        XCTAssertEqual(response.body, .buffer("{\"fuu\":\"baz\"}"))
    }

    func testURLEncodedFormRequestResponse() throws {
        let request = Request(
            headers: [
                "Content-Type": "application/x-www-form-urlencoded; charset=utf-8",
                "Accept": "application/x-www-form-urlencoded"
            ],
            body: "foo=bar"
        )

        let responder = BasicResponder { request in
            XCTAssertEqual(request.content, ["foo": "bar"])
            return try Response(content: ["fuu": "baz"])
        }

        let response = try contentNegotiation.respond(to: request, chainingTo: responder)

        XCTAssertEqual(response.headers["Content-Type"], "application/x-www-form-urlencoded; charset=utf-8")
        XCTAssertEqual(response.body, .buffer("fuu=baz"))
    }
}

extension ContentNegotiationMiddlewareTests {
    static var allTests : [(String, (ContentNegotiationMiddlewareTests) -> () throws -> Void)] {
        return [
            ("testJSONRequestResponse", testJSONRequestResponse),
            ("testURLEncodedFormRequestResponse", testURLEncodedFormRequestResponse)
        ]
    }
}
