import XCTest
import Quark

class TCPTests : XCTestCase {
    func testConnectionRefused() {
        var called = false

        do {
            let connection = try TCPConnection(host: "127.0.0.1", port: 1111)
            try connection.open()
            XCTAssert(false)
        } catch {
            called = true
        }

        XCTAssert(called)
    }

    func testSendClosedSocket() {
        var called = false

        func client(_ port: Int) {
            do {
                let connection = try TCPConnection(host: "127.0.0.1", port: port)
                try connection.open()
                try connection.close()
                try connection.send([])
                XCTAssert(false)
            } catch {
                called = true
            }
        }

        do {
            let port = 2222
            let host = try TCPHost(host: "127.0.0.1", port: port)
            co(client(port))
            _ = try host.accept()
            nap(for: 1.millisecond)
        } catch {
            XCTAssert(false)
        }

        XCTAssert(called)
    }

    func testFlushClosedSocket() {
        var called = false

        func client(_ port: Int) {
            do {
                let connection = try TCPConnection(host: "127.0.0.1", port: port)
                try connection.open()
                try connection.close()
                try connection.flush()
                XCTAssert(false)
            } catch {
                called = true
            }
        }

        do {
            let port = 3333
            let host = try TCPHost(host: "127.0.0.1", port: port)
            co(client(port))
            _ = try host.accept()
            nap(for: 1.millisecond)
        } catch {
            XCTAssert(false)
        }

        XCTAssert(called)
    }

    func testReceiveClosedSocket() {
        var called = false

        func client(_ port: Int) {
            do {
                let connection = try TCPConnection(host: "127.0.0.1", port: port)
                try connection.open()
                try connection.close()
                _ = try connection.receive(1)
                XCTAssert(false)
            } catch {
                called = true
            }
        }

        do {
            let port = 4444
            let host = try TCPHost(host: "127.0.0.1", port: port)
            co(client(port))
            _ = try host.accept()
            nap(for: 1.millisecond)
        } catch {
            XCTAssert(false)
        }

        XCTAssert(called)
    }

    func testSendReceive() {
        func client(_ port: Int) {
            do {
                let connection = try TCPConnection(host: "127.0.0.1", port: port)
                try connection.open()
                try connection.send([123])
            } catch {
                XCTAssert(false)
            }
        }

        do {
            let port = 5555
            let host = try TCPHost(host: "127.0.0.1", port: port)
            co(client(port))
            let connection = try host.accept()
            let data = try connection.receive(upTo: 1)
            XCTAssert(data == [123])
            try connection.close()
        } catch {
            XCTAssert(false)
        }
    }

    func testClientServer() {
        func client(_ port: Int) {
            do {
                let connection = try TCPConnection(host: "127.0.0.1", port: port)
                try connection.open()

                let data = try connection.receiveString(upTo: 3)
                XCTAssert(data == "ABC")

                try connection.send("123456789")
            } catch {
                print(error)
                XCTAssert(false)
            }
        }

        do {
            let port = 6666
            let host = try TCPHost(host: "127.0.0.1", port: port)

            co(client(port))

            let connection = try host.accept()
            let deadline = 30.milliseconds.fromNow()

            do {
                _ = try connection.receive(upTo: 16, timingOut: deadline)
                XCTAssert(false)
            } catch {
                XCTAssert(true)
            }

            let diff = now() - deadline
            XCTAssert(diff > -300 && diff < 300)

            try connection.send("ABC")

            let data = try connection.receive(upTo: 9)
            XCTAssert(data == "123456789")
        } catch {
            print(error)
            XCTAssert(false)
        }
    }
}

extension TCPTests {
    static var allTests : [(String, (TCPTests) -> () throws -> Void)] {
        return [
            ("testConnectionRefused", testConnectionRefused),
            ("testSendClosedSocket", testSendClosedSocket),
            ("testFlushClosedSocket", testFlushClosedSocket),
            ("testReceiveClosedSocket", testReceiveClosedSocket),
            ("testSendReceive", testSendReceive),
            ("testClientServer", testClientServer),
        ]
    }
}
