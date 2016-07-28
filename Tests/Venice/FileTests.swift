import XCTest
import Quark

class FileTests : XCTestCase {
    func testReadWrite() {
        do {
            let file = try File(path: "/tmp/zewo-test-file", mode: .truncateReadWrite)
            try file.write("abc")
            XCTAssert(try file.tell() == 3)
            _ = try file.seek(position: 0)
            var data = try file.read(3)
            XCTAssert(data == "abc".data)
            XCTAssert(!file.eof)
            data = try file.read(3)
            XCTAssert(data.count == 0)
            XCTAssert(file.eof)
            _ = try file.seek(position: 0)
            XCTAssert(!file.eof)
            _ = try file.seek(position: 3)
            XCTAssert(!file.eof)
            data = try file.read(6)
            XCTAssert(data.count == 0)
            XCTAssert(file.eof)
        } catch {
            XCTFail()
        }
    }

    func testReadAllFile() {
        do {
            let file = try File(path: "/tmp/zewo-test-file", mode: .truncateReadWrite)
            let word = "hello"
            try file.write(word)
            _ = try file.seek(position: 0)
            let data = try file.readAllBytes()
            XCTAssert(data.count == word.utf8.count)
        } catch {
            XCTFail()
        }
    }

    func testDelete() {
        do {
            let file = try File(path: "/tmp/zewo-test-file", mode: .truncateReadWrite)
            let word = "hello"
            try file.write(word)
            try file.close()
            try File.removeItem(at:"/tmp/zewo-test-file")
        } catch {
            XCTFail()
        }
    }

    func testFileSize() {
        do {
            let file = try File(path: "/tmp/zewo-test-file", mode: .truncateReadWrite)
            try file.write("hello")
            XCTAssertEqual(file.length, 5)
            try file.write(" world")
            XCTAssertEqual(file.length, 11)
        } catch {
            XCTFail()
        }
    }

    func testZero() {
        do {
            let file = try File(path: "/dev/zero")
            let count = 4096
            let length = 256

            for _ in 0 ..< count {
                let data = try file.read(length)
                XCTAssertEqual(data.count, length)
            }
        } catch {
            XCTFail()
        }
    }

    func testRandom() {
        #if os(OSX)
        do {
            let file = try File(path: "/dev/random")
            let count = 4096
            let length = 256

            for _ in 0 ..< count {
                let data = try file.read(length)
                XCTAssertEqual(data.count, length)
            }
        } catch {
            XCTFail()
        }
        #endif
    }
}

extension FileTests {
    static var allTests : [(String, (FileTests) -> () throws -> Void)] {
        return [
            ("testReadWrite", testReadWrite),
            ("testReadAllFile", testReadAllFile),
             ("testFileSize", testFileSize),
            ("testZero", testZero),
            ("testRandom", testRandom),
            ("testDelete", testDelete),
        ]
    }
}
