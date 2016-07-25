import XCTest
import Quark

class IPTests : XCTestCase {
    func testLocalIPV4() {
        do {
            let _ = try IP(port: 5555, mode: .ipV4)
        } catch {
            XCTAssert(false)
        }
    }

    func testLocalIPV6() {
        do {
            let _ = try IP(port: 5555, mode: .ipV6)
        } catch {
            XCTAssert(false)
        }
    }

    func testLocalIPV4Prefered() {
        do {
            let _ = try IP(port: 5555, mode: .ipV4Prefered)
        } catch {
            XCTAssert(false)
        }
    }

    func testLocalIPV6Prefered() {
        do {
            let _ = try IP(port: 5555, mode: .ipV6Prefered)
        } catch {
            XCTAssert(false)
        }
    }

    func testNetworkInterfaceIPV4() {
        do {
            let _ = try IP(localAddress: "lo0", port: 5555, mode: .ipV4)
        } catch {
            XCTAssert(true)
        }
    }

    func testNetworkInterfaceIPV6() {
        do {
            let _ = try IP(localAddress: "lo0", port: 5555, mode: .ipV6)
        } catch {
            XCTAssert(true)
        }
    }

    func testNetworkInterfaceIPV4Prefered() {
        do {
            let _ = try IP(localAddress: "lo0", port: 5555, mode: .ipV4Prefered)
        } catch {
            XCTAssert(true)
        }
    }

    func testNetworkInterfaceIPV6Prefered() {
        do {
            let _ = try IP(localAddress: "lo0", port: 5555, mode: .ipV6Prefered)
        } catch {
            XCTAssert(true)
        }
    }

    func testRemoteIPV4() {
        do {
            let _ = try IP(remoteAddress: "127.0.0.1", port: 5555, mode: .ipV4)
        } catch {
            XCTAssert(true)
        }
    }

    func testRemoteIPV6() {
        do {
            let _ = try IP(remoteAddress: "::1", port: 5555, mode: .ipV6)
        } catch {
            XCTAssert(true)
        }
    }

    func testRemoteIPV4Prefered() {
        do {
            let _ = try IP(remoteAddress: "127.0.0.1", port: 5555, mode: .ipV4Prefered)
        } catch {
            XCTAssert(true)
        }
    }

    func testRemoteIPV6Prefered() {
        do {
            let _ = try IP(remoteAddress: "::1", port: 5555, mode: .ipV6Prefered)
        } catch {
            XCTAssert(true)
        }
    }

    func testInvalidPortIPV4() {
        do {
            let _ = try IP(port: 70000, mode: .ipV4)
        } catch {
            XCTAssert(true)
        }
    }

    func testInvalidPortIPV6() {
        do {
            let _ = try IP(port: 70000, mode: .ipV6)
        } catch {
            XCTAssert(true)
        }
    }

    func testInvalidPortIPV4Prefered() {
        do {
            let _ = try IP(port: 70000, mode: .ipV4Prefered)
        } catch {
            XCTAssert(true)
        }
    }

    func testInvalidPortIPV6Prefered() {
        do {
            let _ = try IP(port: 70000, mode: .ipV6Prefered)
        } catch {
            XCTAssert(true)
        }
    }

    func testInvalidNetworkInterfaceIPV4() {
        do {
            let _ = try IP(localAddress: "yo-yo ma", port: 5555, mode: .ipV4)
        } catch {
            XCTAssert(true)
        }
    }

    func testInvalidNetworkInterfaceIPV6() {
        do {
            let _ = try IP(localAddress: "yo-yo ma", port: 5555, mode: .ipV6)
        } catch {
            XCTAssert(true)
        }
    }

    func testInvalidNetworkInterfaceIPV4Prefered() {
        do {
            let _ = try IP(localAddress: "yo-yo ma", port: 5555, mode: .ipV4Prefered)
        } catch {
            XCTAssert(true)
        }
    }

    func testInvalidNetworkInterfaceIPV6Prefered() {
        do {
            let _ = try IP(localAddress: "yo-yo ma", port: 5555, mode: .ipV6Prefered)
        } catch {
            XCTAssert(true)
        }
    }

    func testRemoteInvalidPortIPV4() {
        do {
            let _ = try IP(remoteAddress: "127.0.0.1", port: 70000, mode: .ipV4)
        } catch {
            XCTAssert(true)
        }
    }

    func testRemoteInvalidPortIPV6() {
        do {
            let _ = try IP(remoteAddress: "::1", port: 70000, mode: .ipV6)
        } catch {
            XCTAssert(true)
        }
    }

    func testRemoteInvalidPortIPV4Prefered() {
        do {
            let _ = try IP(remoteAddress: "127.0.0.1", port: 70000, mode: .ipV4Prefered)
        } catch {
            XCTAssert(true)
        }
    }

    func testRemoteInvalidPortIPV6Prefered() {
        do {
            let _ = try IP(remoteAddress: "::1", port: 70000, mode: .ipV6Prefered)
        } catch {
            XCTAssert(true)
        }
    }
}

extension IPTests {
    static var allTests : [(String, (IPTests) -> () throws -> Void)] {
        return [
            ("testLocalIPV4", testLocalIPV4),
            ("testLocalIPV6", testLocalIPV6),
            ("testLocalIPV4Prefered", testLocalIPV4Prefered),
            ("testLocalIPV6Prefered", testLocalIPV6Prefered),
            ("testNetworkInterfaceIPV4", testNetworkInterfaceIPV4),
            ("testNetworkInterfaceIPV6", testNetworkInterfaceIPV6),
            ("testNetworkInterfaceIPV4Prefered", testNetworkInterfaceIPV4Prefered),
            ("testNetworkInterfaceIPV6Prefered", testNetworkInterfaceIPV6Prefered),
            ("testRemoteIPV4", testRemoteIPV4),
            ("testRemoteIPV6", testRemoteIPV6),
            ("testRemoteIPV4Prefered", testRemoteIPV4Prefered),
            ("testRemoteIPV6Prefered", testRemoteIPV6Prefered),
            ("testInvalidPortIPV4", testInvalidPortIPV4),
            ("testInvalidPortIPV6", testInvalidPortIPV6),
            ("testInvalidPortIPV4Prefered", testInvalidPortIPV4Prefered),
            ("testInvalidPortIPV6Prefered", testInvalidPortIPV6Prefered),
            ("testInvalidNetworkInterfaceIPV4", testInvalidNetworkInterfaceIPV4),
            ("testInvalidNetworkInterfaceIPV6", testInvalidNetworkInterfaceIPV6),
            ("testInvalidNetworkInterfaceIPV4Prefered", testInvalidNetworkInterfaceIPV4Prefered),
            ("testInvalidNetworkInterfaceIPV6Prefered", testInvalidNetworkInterfaceIPV6Prefered),
            ("testRemoteInvalidPortIPV4", testRemoteInvalidPortIPV4),
            ("testRemoteInvalidPortIPV6", testRemoteInvalidPortIPV6),
            ("testRemoteInvalidPortIPV4Prefered", testRemoteInvalidPortIPV4Prefered),
            ("testRemoteInvalidPortIPV6Prefered", testRemoteInvalidPortIPV6Prefered),
        ]
    }
}
