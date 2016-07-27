import XCTest
import Quark

let requestCount = [
    1,
    2,
    5
]

let bufferSizes = [
    1,
    2,
    4,
    32,
    512,
    2048
]

let methods: [S4.Method] = [
    .delete,
    .get,
    .head,
    .post,
    .put,
    .options,
    .trace,
    .patch,
    .other(method: "COPY"),
    .other(method: "LOCK"),
    .other(method: "MKCOL"),
    .other(method: "MOVE"),
    .other(method: "PROPFIND"),
    .other(method: "PROPPATCH"),
    .other(method: "SEARCH"),
    .other(method: "UNLOCK"),
    .other(method: "BIND"),
    .other(method: "REBIND"),
    .other(method: "UNBIND"),
    .other(method: "ACL"),
    .other(method: "REPORT"),
    .other(method: "MKACTIVITY"),
    .other(method: "CHECKOUT"),
    .other(method: "MERGE"),
    .other(method: "NOTIFY"),
    .other(method: "SUBSCRIBE"),
    .other(method: "UNSUBSCRIBE"),
    .other(method: "PURGE"),
    .other(method: "MKCALENDAR"),
]

class RequestParserTests : XCTestCase {
    func testInvalidMethod() {
        var called = false
        do {
            let data = "INVALID / HTTP/1.1\r\n\r\n"
            let stream = Drain(for: data)
            let parser = RequestParser(stream: stream)
            _ = try parser.parse()
            XCTFail("Invalid method should fail.")
        } catch {
            called = true
        }
        XCTAssert(called)
    }

    func testInvalidURI() {
        var called = false
        do {
            let data = "GET huehue HTTP/1.1\r\n\r\n"
            let stream = Drain(for: data)
            let parser = RequestParser(stream: stream)
            _ = try parser.parse()
            XCTFail("Invalid URI should fail.")
        } catch {
            called = true
        }
        XCTAssert(called)
    }

    func testInvalidHTTPVersion() {
        var called = false
        do {
            let data = "GET / HUEHUE\r\n\r\n"
            let stream = Drain(for: data)
            let parser = RequestParser(stream: stream)
            _ = try parser.parse()
            XCTFail("Invalid URI should fail.")
        } catch {
            called = true
        }
        XCTAssert(called)
    }

    func testInvalidDoubleConnectMethod() {
        var called = false
        do {
            let data = "CONNECT / HTTP/1.1\r\n\r\nCONNECT / HTTP/1.1\r\n\r\n"
            let stream = Drain(for: data)
            let parser = RequestParser(stream: stream)
            _ = try parser.parse()
            XCTFail("Connect method should only happen once.")
        } catch {
            called = true
        }
        XCTAssert(called)
    }

    func testConnectMethod() {
        do {
            let data = "CONNECT / HTTP/1.1\r\n\r\n"
            let stream = Drain(for: data)
            let parser = RequestParser(stream: stream)
            let request = try parser.parse()
            XCTAssert(request.method == .connect)
            XCTAssert(request.uri.path == "/")
            XCTAssert(request.version.major == 1)
            XCTAssert(request.version.minor == 1)
            XCTAssert(request.headers.count == 0)
        } catch {
            XCTFail(String(error))
        }
    }

    func check(request: String, count: Int, bufferSize: Int, test: (Request) -> Void) {
        do {
            var data = ""

            for _ in 0 ..< count {
                data += request
            }

            let stream = Drain(for: data)
            let parser = RequestParser(stream: stream, bufferSize: bufferSize)

            for _ in 0 ..< count {
                try test(parser.parse())
            }
        } catch {
            XCTFail(String(error))
        }
    }

    func testShortRequests() {
        for bufferSize in bufferSizes {
            for count in requestCount {
                for method in methods {
                    let request = "\(method) / HTTP/1.1\r\n\r\n"
                    check(request: request, count: count, bufferSize: bufferSize) { request in
                        XCTAssert(request.method == method)
                        XCTAssert(request.uri.path == "/")
                        XCTAssert(request.version.major == 1)
                        XCTAssert(request.version.minor == 1)
                        XCTAssert(request.headers.count == 0)
                    }
                }
            }
        }
    }

    func testMediumRequests() {
        for bufferSize in bufferSizes {
            for count in requestCount {
                for method in methods {
                    let request = "\(method) / HTTP/1.1\r\nHost: zewo.co\r\n\r\n"
                    check(request: request, count: count, bufferSize: bufferSize) { request in
                        XCTAssert(request.method == method)
                        XCTAssert(request.uri.path == "/")
                        XCTAssert(request.version.major == 1)
                        XCTAssert(request.version.minor == 1)
                        XCTAssert(request.headers["Host"] == "zewo.co")
                    }
                }
            }
        }
    }

    func testCookiesRequest() {
        for bufferSize in bufferSizes {
            for count in requestCount {
                for method in methods {
                    let request = "\(method) / HTTP/1.1\r\nHost: zewo.co\r\nCookie: server=zewo, lang=swift\r\n\r\n"
                    check(request: request, count: count, bufferSize: bufferSize) { request in
                        XCTAssert(request.method == method)
                        XCTAssert(request.uri.path == "/")
                        XCTAssert(request.version.major == 1)
                        XCTAssert(request.version.minor == 1)
                        XCTAssert(request.headers["Host"] == "zewo.co")
                        XCTAssert(request.headers["Cookie"] == "server=zewo, lang=swift")
                    }
                }
            }
        }
    }

    func testBodyRequest() {
        for bufferSize in bufferSizes {
            for count in requestCount {
                for method in methods {
                    let request = "\(method) / HTTP/1.1\r\nContent-Length: 4\r\n\r\nZewo"
                    check(request: request, count: count, bufferSize: bufferSize) { request in
                        XCTAssert(request.method == method)
                        XCTAssert(request.uri.path == "/")
                        XCTAssert(request.version.major == 1)
                        XCTAssert(request.version.minor == 1)
                        XCTAssert(request.headers["Content-Length"] == "4")
                        XCTAssert(request.body == .buffer("Zewo"))
                    }
                }
            }
        }
    }

    func testManyRequests() {
        var request = ""

        for _ in 0 ..< 1_000 {
            request += "POST / HTTP/1.1\r\nContent-Length: 4\r\n\r\nZewo"
        }

        measure {
            self.check(request: request, count: 1, bufferSize: 4096) { request in
                XCTAssert(request.method == .post)
                XCTAssert(request.uri.path == "/")
                XCTAssert(request.version.major == 1)
                XCTAssert(request.version.minor == 1)
                XCTAssert(request.headers["Content-Length"] == "4")
                XCTAssert(request.body == .buffer("Zewo"))
            }
        }
    }

   // func testChunkedEncoding() {
   //     let parser = HTTPRequestParser { request in
   //         XCTAssert(request.method == .GET)
   //         XCTAssert(request.uri.path == "/")
   //         XCTAssert(request.majorVersion == 1)
   //         XCTAssert(request.minorVersion == 1)
   //         XCTAssert(request.headers["Transfer-Encoding"] == "chunked")
   //         XCTAssert(request.body == "Zewo".bytes)
   //     }

   //     do {
   //         let data = ("GET / HTTP/1.1\r\n" +
   //             "Transfer-Encoding: chunked\r\n" +
   //             "\r\n" +
   //             "4\r\n" +
   //             "Zewo\r\n")
   //         try parser.parse(data)
   //     } catch {
   //         XCTAssert(false)
   //     }
   // }

   // func testIncorrectContentLength() {
   //     let parser = HTTPRequestParser { _ in
   //         XCTAssert(false)
   //     }

   //     do {
   //         let data = ("POST / HTTP/1.1\r\n" +
   //             "Content-Length: 5\r\n" +
   //             "\r\n" +
   //             "Zewo")
   //         try parser.parse(data)
   //     } catch {
   //         XCTAssert(true)
   //     }
   // }

   // func testIncorrectChunkSize() {
   //     let parser = HTTPRequestParser { _ in
   //         XCTAssert(false)
   //     }

   //     do {
   //         let data = ("GET / HTTP/1.1\r\n" +
   //             "Transfer-Encoding: chunked\r\n" +
   //             "\r\n" +
   //             "5\r\n" +
   //             "Zewo\r\n")
   //         try parser.parse(data)
   //     } catch {
   //         XCTAssert(true)
   //     }
   // }

   // func testInvalidChunkSize() {
   //     let parser = HTTPRequestParser { _ in
   //         XCTAssert(false)
   //     }

   //     do {
   //         let data = ("GET / HTTP/1.1\r\n" +
   //             "Transfer-Encoding: chunked\r\n" +
   //             "\r\n" +
   //             "x\r\n" +
   //             "Zewo\r\n")
   //         try parser.parse(data)
   //     } catch {
   //         XCTAssert(true)
   //     }
   // }

   // func testConnectionKeepAlive() {
   //     let parser = HTTPRequestParser { request in
   //         XCTAssert(request.method == .GET)
   //         XCTAssert(request.uri.path == "/")
   //         XCTAssert(request.majorVersion == 1)
   //         XCTAssert(request.minorVersion == 1)
   //         XCTAssert(request.headers["Connection"] == "keep-alive")
   //     }

   //     do {
   //         let data = ("GET / HTTP/1.1\r\n" +
   //             "Connection: keep-alive\r\n" +
   //             "\r\n")
   //         try parser.parse(data)
   //     } catch {
   //         XCTAssert(false)
   //     }
   // }

   // func testConnectionClose() {
   //     let parser = HTTPRequestParser { request in
   //         XCTAssert(request.method == .GET)
   //         XCTAssert(request.uri.path == "/")
   //         XCTAssert(request.majorVersion == 1)
   //         XCTAssert(request.minorVersion == 1)
   //         XCTAssert(request.headers["Connection"] == "close")
   //     }

   //     do {
   //         let data = ("GET / HTTP/1.1\r\n" +
   //             "Connection: close\r\n" +
   //             "\r\n")
   //         try parser.parse(data)
   //     } catch {
   //         XCTAssert(false)
   //     }
   // }

   // func testRequestHTTP1_0() {
   //     let parser = HTTPRequestParser { request in
   //         XCTAssert(request.method == .GET)
   //         XCTAssert(request.uri.path == "/")
   //         XCTAssert(request.majorVersion == 1)
   //         XCTAssert(request.minorVersion == 0)
   //     }

   //     do {
   //         let data = ("GET / HTTP/1.0\r\n" +
   //             "\r\n")
   //         try parser.parse(data)
   //     } catch {
   //         XCTAssert(false)
   //     }
   // }
}

extension RequestParserTests {
    static var allTests: [(String, (RequestParserTests) -> () throws -> Void)] {
        return [
            ("testInvalidMethod", testInvalidMethod),
            ("testInvalidURI", testInvalidURI),
            ("testInvalidHTTPVersion", testInvalidHTTPVersion),
            ("testInvalidDoubleConnectMethod", testInvalidDoubleConnectMethod),
            ("testConnectMethod", testConnectMethod),
            ("testShortRequests", testShortRequests),
            ("testMediumRequests", testMediumRequests),
            ("testCookiesRequest", testCookiesRequest),
            ("testBodyRequest", testBodyRequest),
            ("testManyRequests", testManyRequests),
        ]
    }
}
