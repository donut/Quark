import XCTest
import Quark

let responseCount = [
    1,
    2,
    5
]

let statuses: [Status] = [
    .`continue`,
    .switchingProtocols,
    .processing,

    .ok,
    .created,
    .accepted,
    .nonAuthoritativeInformation,
    .noContent,
    .resetContent,
    .partialContent,

    .multipleChoices,
    .movedPermanently,
    .found,
    .seeOther,
    .notModified,
    .useProxy,
    .switchProxy,
    .temporaryRedirect,
    .permanentRedirect,

    .badRequest,
    .unauthorized,
    .paymentRequired,
    .forbidden,
    .notFound,
    .methodNotAllowed,
    .notAcceptable,
    .proxyAuthenticationRequired,
    .requestTimeout,
    .conflict,
    .gone,
    .lengthRequired,
    .preconditionFailed,
    .requestEntityTooLarge,
    .requestURITooLong,
    .unsupportedMediaType,
    .requestedRangeNotSatisfiable,
    .expectationFailed,
    .imATeapot,
    .authenticationTimeout,
    .enhanceYourCalm,
    .unprocessableEntity,
    .locked,
    .failedDependency,
    .preconditionRequired,
    .tooManyRequests,
    .requestHeaderFieldsTooLarge,

    .internalServerError,
    .notImplemented,
    .badGateway,
    .serviceUnavailable,
    .gatewayTimeout,
    .httpVersionNotSupported,
    .variantAlsoNegotiates,
    .insufficientStorage,
    .loopDetected,
    .notExtended,
    .networkAuthenticationRequired,
]

class ResponseParserTests : XCTestCase {
    func testInvalidHTTPVersion() {
        var called = false
        do {
            let data = "HUEHUE 200 OK\r\n\r\n"
            let stream = Drain(for: data)
            let parser = ResponseParser(stream: stream)
            _ = try parser.parse()
            XCTFail("Invalid HTTP version should fail.")
        } catch {
            called = true
        }
        XCTAssert(called)
    }

    func check(response: String, count: Int, bufferSize: Int, test: (Response) -> Void) {
        do {
            var data = ""

            for _ in 0 ..< count {
                data += response
            }

            let stream = Drain(for: data)
            let parser = ResponseParser(stream: stream, bufferSize: bufferSize)

            for _ in 0 ..< count {
                try test(parser.parse())
            }
        } catch {
            XCTFail(String(error))
        }
    }

    func testShortResponses() {
        for bufferSize in bufferSizes {
            for count in responseCount {
                for status in statuses {
                    let response = "HTTP/1.1 \(status.statusCode) \(status.reasonPhrase)\r\nContent-Length: 0\r\n\r\n"
                    check(response: response, count: count, bufferSize: bufferSize) { response in
                        XCTAssert(response.status == status)
                        XCTAssert(response.version.major == 1)
                        XCTAssert(response.version.minor == 1)
                        XCTAssert(response.headers.count == 1)
                        XCTAssert(response.headers["Content-Length"] == "0")
                    }
                }
            }
        }
    }

    func testCookiesResponse() {
        for bufferSize in bufferSizes {
            for count in responseCount {
                for status in statuses {
                    let response = "HTTP/1.1 \(status.statusCode) \(status.reasonPhrase)\r\nContent-Length: 0\r\nHost: zewo.co\r\nSet-Cookie: server=zewo\r\nSet-Cookie: lang=swift\r\n\r\n"
                    check(response: response, count: count, bufferSize: bufferSize) { response in
                        XCTAssert(response.status == status)
                        XCTAssert(response.version.major == 1)
                        XCTAssert(response.version.minor == 1)
                        XCTAssert(response.headers["Host"] == "zewo.co")
                        XCTAssert(response.cookies.contains(AttributedCookie(name: "server", value: "zewo")))
                        XCTAssert(response.cookies.contains(AttributedCookie(name: "lang", value: "swift")))
                    }
                }
            }
        }
    }

    func testBodyResponse() {
        for bufferSize in bufferSizes {
            for count in responseCount {
                for status in statuses {
                    let response = "HTTP/1.1 \(status.statusCode) \(status.reasonPhrase)\r\nContent-Length: 4\r\n\r\nZewo"
                    check(response: response, count: count, bufferSize: bufferSize) { response in
                        XCTAssert(response.status == status)
                        XCTAssert(response.version.major == 1)
                        XCTAssert(response.version.minor == 1)
                        XCTAssert(response.headers["Content-Length"] == "4")
                        XCTAssert(response.body == .buffer("Zewo"))
                    }
                }
            }
        }
    }

    func testManyResponses() {
        var response = ""

        for _ in 0 ..< 1_000 {
            response += "HTTP/1.1 200 OK\r\nContent-Length: 4\r\n\r\nZewo"
        }

        measure {
            self.check(response: response, count: 1, bufferSize: 4096) { response in
                XCTAssert(response.status == .ok)
                XCTAssert(response.version.major == 1)
                XCTAssert(response.version.minor == 1)
                XCTAssert(response.headers["Content-Length"] == "4")
                XCTAssert(response.body == .buffer("Zewo"))
            }
        }
    }

   // func testChunkedEncoding() {
   //     let parser = HTTPResponseParser { response in
   //         XCTAssert(response.method == .GET)
   //         XCTAssert(response.uri.path == "/")
   //         XCTAssert(response.majorVersion == 1)
   //         XCTAssert(response.minorVersion == 1)
   //         XCTAssert(response.headers["Transfer-Encoding"] == "chunked")
   //         XCTAssert(response.body == "Zewo".bytes)
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
   //     let parser = HTTPResponseParser { _ in
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
   //     let parser = HTTPResponseParser { _ in
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
   //     let parser = HTTPResponseParser { _ in
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
   //     let parser = HTTPResponseParser { response in
   //         XCTAssert(response.method == .GET)
   //         XCTAssert(response.uri.path == "/")
   //         XCTAssert(response.majorVersion == 1)
   //         XCTAssert(response.minorVersion == 1)
   //         XCTAssert(response.headers["Connection"] == "keep-alive")
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
   //     let parser = HTTPResponseParser { response in
   //         XCTAssert(response.method == .GET)
   //         XCTAssert(response.uri.path == "/")
   //         XCTAssert(response.majorVersion == 1)
   //         XCTAssert(response.minorVersion == 1)
   //         XCTAssert(response.headers["Connection"] == "close")
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

   // func testResponseHTTP1_0() {
   //     let parser = HTTPResponseParser { response in
   //         XCTAssert(response.method == .GET)
   //         XCTAssert(response.uri.path == "/")
   //         XCTAssert(response.majorVersion == 1)
   //         XCTAssert(response.minorVersion == 0)
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

extension ResponseParserTests {
    static var allTests: [(String, (ResponseParserTests) -> () throws -> Void)] {
        return [
            ("testInvalidHTTPVersion", testInvalidHTTPVersion),
            ("testShortResponses", testShortResponses),
            ("testCookiesResponse", testCookiesResponse),
            ("testBodyResponse", testBodyResponse),
            ("testManyResponses", testManyResponses),
        ]
    }
}
