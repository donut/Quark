import XCTest
@testable import Quark

class RedirectMiddlewareTests : XCTestCase {
    let middleware = RedirectMiddleware(redirectTo: "/over-there", if: { $0.method == .get })

    func testDoesRedirect() throws {
        let getRequest = Request(method: .get)

        let chain = BasicResponder { _ in XCTFail("Should have redirected"); return Response() }
        let response = try middleware.respond(to: getRequest, chainingTo: chain)

        XCTAssertEqual(response.status, .found)
        XCTAssertEqual(response.headers["location"], "/over-there")
    }

    func testDoesntRedirect() throws {
        let postRequest = Request(method: .post)

        let chain = BasicResponder { _ in return Response(status: .ok) }
        let response = try middleware.respond(to: postRequest, chainingTo: chain)

        XCTAssertEqual(response.status, .ok)
        XCTAssertNotEqual(response.headers["location"], "/over-there")
    }
}

extension RedirectMiddlewareTests {
    static var allTests : [(String, (RedirectMiddlewareTests) -> () throws -> Void)] {
        return [
            ("testDoesRedirect", testDoesRedirect),
            ("testDoesntRedirect", testDoesntRedirect)
        ]
    }
}
