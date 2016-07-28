import XCTest
@testable import Quark

class MessageTests : XCTestCase {
    func testHeaderCaseInsensitivity() {
        var request = Request()
        request.headers["Content-Type"] = "application/json"
        XCTAssertEqual(request.headers["content-TYPE"], "application/json")
    }

    func testContentType() {
        let request = Request(headers: ["Content-Type": "application/json"])
        XCTAssertEqual(request.contentType, MediaType(type: "application", subtype: "json"))
    }

    let data: C7.Data = [0x00, 0x01, 0x02, 0x03]

    func checkBodyProperties(_ body: Body) {
        var bodyForBuffer = body
        var bodyForReceiver = body
        var bodyForSender = body

        XCTAssert(data == (try! bodyForBuffer.becomeBuffer()), "Garbled buffer bytes")
        switch bodyForBuffer {
        case .buffer(let d):
            XCTAssert(data == d, "Garbled buffer bytes")
        default:
            XCTFail("Incorrect type")
        }

        bodyForReceiver.forceReopenDrain()
        let receiverDrain = Drain(for: try! bodyForReceiver.becomeReceiver())
        XCTAssert(data == receiverDrain.data, "Garbled receiver bytes")
        switch bodyForReceiver {
        case .receiver(let stream):
            bodyForReceiver.forceReopenDrain()
            let receiverDrain = Drain(for: stream)
            XCTAssert(data == receiverDrain.data, "Garbed receiver bytes")
        default:
            XCTFail("Incorrect type")
        }


        let senderDrain = Drain()
        bodyForReceiver.forceReopenDrain()
        do {
            try bodyForSender.becomeSender()(senderDrain)

        } catch {
            XCTFail("Drain threw error \(error)")
        }
        XCTAssert(data == senderDrain.data, "Garbled sender bytes")

        switch bodyForSender {
        case .sender(let closure):
            let senderDrain = Drain()
            bodyForReceiver.forceReopenDrain()
            do {
                try closure(senderDrain)
            } catch {
                XCTFail("Drain threw error \(error)")
            }
            XCTAssert(data == senderDrain.data, "Garbed sender bytes")
        default:
            XCTFail("Incorrect type")
        }
    }

    func testSender() {
        let sender = Body.sender { stream in
            try stream.send(self.data)
        }
        checkBodyProperties(sender)
    }

    func testReceiver() {
        let drain = Drain(for: data)
        let receiver = Body.receiver(drain)
        checkBodyProperties(receiver)
    }

    func testBuffer() {
        let buffer = Body.buffer(data)
        checkBodyProperties(buffer)
    }

    func testBodyEquality() {
        let buffer = Body.buffer(data)

        let drain = Drain(for: data)
        let receiver = Body.receiver(drain)

        let sender = Body.sender { stream in
            try stream.send(self.data)
        }

        XCTAssertEqual(buffer, buffer)
        XCTAssertNotEqual(buffer, receiver)
        XCTAssertNotEqual(buffer, sender)
        XCTAssertNotEqual(receiver, sender)
    }
}

extension MessageTests {
    static var allTests: [(String, (MessageTests) -> () throws -> Void)] {
        return [
            ("testHeaderCaseInsensitivity", testHeaderCaseInsensitivity),
            ("testContentType", testContentType),
            ("testSender", testSender),
            ("testReceiver", testReceiver),
            ("testBuffer", testBuffer),
        ]
    }
}

extension Body {
    mutating func forceReopenDrain() {
        if let drain = (try! self.becomeReceiver()) as? Drain {
            drain.closed = false
        }
    }
}
