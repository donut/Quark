import XCTest
@testable import Quark

class LoggerTests : XCTestCase {
    func testLogger() throws {
        let appender = StandardOutputAppender()
        let logger = Logger(appenders: [appender])
        logger.trace("foo")
        XCTAssertTrue(appender.lastMessage.hasSuffix("foo"))
        logger.debug("bar")
        XCTAssertTrue(appender.lastMessage.hasSuffix("bar"))
        logger.info("foo")
        XCTAssertTrue(appender.lastMessage.hasSuffix("foo"))
        logger.warning("bar")
        XCTAssertTrue(appender.lastMessage.hasSuffix("bar"))
        logger.error("foo")
        XCTAssertTrue(appender.lastMessage.hasSuffix("foo"))
        logger.fatal("bar")
        XCTAssertTrue(appender.lastMessage.hasSuffix("bar"))
        appender.levels = [.warning]
        logger.error("foo")
        XCTAssertEqual(appender.lastMessage, "")
        struct Error : ErrorProtocol, CustomStringConvertible {
            let description: String
        }
        logger.warning("foo", error: Error(description: "bar"))
        XCTAssertTrue(appender.lastMessage.hasSuffix("foo:bar"))
    }
}

extension LoggerTests {
    static var allTests : [(String, (LoggerTests) -> () throws -> Void)] {
        return [
            ("testLogger", testLogger),
        ]
    }
}
