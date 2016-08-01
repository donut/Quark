import XCTest
@testable import Quark

struct TestServer : ConfigurableServer {
    let middleware: [Middleware]
    let responder: Responder

    init(middleware: [Middleware], responder: Responder, configuration: StructuredData) throws {
        self.middleware = middleware
        self.responder = responder
        XCTAssertEqual(configuration["foo"], "bar")
    }

    func start() throws {
        let request = Request()
        let response = try middleware.chain(to: responder).respond(to: request)
        XCTAssertEqual(response.status, .ok)
        called = true
    }
}

struct TestResponderRepresentable : ResponderRepresentable {
    var responder: Responder {
        return BasicResponder { _ in
            return Response()
        }
    }
}

var called = false

class QuarkTests : XCTestCase {
    func testExample() throws {
        let file = try File(path: "/tmp/TestConfiguration.swift", mode: .truncateWrite)
        try file.write("import Quark\n\nconfiguration = [\"foo\": \"bar\"]")
        configure(configurationFile: "/tmp/TestConfiguration.swift", server: TestServer.self) { (configuration: StructuredData) in
            XCTAssertEqual(configuration["foo"], "bar")
            return TestResponderRepresentable()
        }
        XCTAssertTrue(called)
    }
}

extension QuarkTests {
    static var allTests : [(String, (QuarkTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
