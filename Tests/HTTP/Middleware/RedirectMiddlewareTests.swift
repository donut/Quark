import XCTest
@testable import Quark

class RedirectMiddlewareTests : XCTestCase {
    let redirect = RedirectMiddleware(redirectTo: "/over-there", if: { $0.method == .get })

    func testDoesRedirect() throws {
        let request = Request(method: .get)

        let responder = BasicResponder { _ in
            XCTFail("Should have redirected")
            return Response()
        }

        let response = try redirect.respond(to: request, chainingTo: responder)

        XCTAssertEqual(response.status, .found)
        XCTAssertEqual(response.headers["location"], "/over-there")
    }

    func testDoesntRedirect() throws {
        let request = Request(method: .post)

        let responder = BasicResponder { _ in
            return Response(status: .ok)
        }

        let response = try redirect.respond(to: request, chainingTo: responder)

        XCTAssertEqual(response.status, .ok)
        XCTAssertNotEqual(response.headers["location"], "/over-there")
    }
}

extension RedirectMiddlewareTests {
    static var allTests : [(String, (RedirectMiddlewareTests) -> () throws -> Void)] {
        return [
            ("testDoesRedirect", testDoesRedirect),
            ("testDoesntRedirect", testDoesntRedirect),
        ]
    }
}
