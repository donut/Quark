import XCTest
@testable import Quark

class StringStream : C7.Stream {
    let input: String
    var output = ""
    var receivedText = false
    var closed: Bool = false

    init(input: String? = nil) {
        self.input = input ?? ""
    }

    func close() throws {}

    func flush(timingOut deadline: Double) throws {}

    func send(_ data: C7.Data, timingOut deadline: Double) throws {
        self.output += String(data)
    }

    func receive(upTo byteCount: Int, timingOut deadline: Double) throws -> C7.Data {
        guard receivedText else {
            receivedText = true
            closed = true
            return Data(input)
        }
        return Data()
    }
}

class HTTPSerializerTests: XCTestCase {
    func testSerializeBuffer() {
        let outStream = StringStream()
        let serializer = ResponseSerializer(stream: outStream)
        let response = Response(body: "text")

        try! serializer.serialize(response)
        XCTAssertEqual(outStream.output, "HTTP/1.1 200 OK\r\nContent-Length: 4\r\n\r\ntext")
    }

    func testSerializeReceiverStream() {
        let inStream = StringStream(input: "text")
        let outStream = StringStream()
        let serializer = ResponseSerializer(stream: outStream)
        let response = Response(body: inStream)

        try! serializer.serialize(response)
        XCTAssertEqual(outStream.output, "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n4\r\ntext\r\n0\r\n\r\n")
    }

    func testSerializeSenderStream() {
        let outStream = StringStream()
        let serializer = ResponseSerializer(stream: outStream)

        let response = Response { (stream: SendingStream) in
            try stream.send("text")
        }

        try! serializer.serialize(response)
        XCTAssertEqual(outStream.output, "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n4\r\ntext\r\n0\r\n\r\n")
    }
}

extension HTTPSerializerTests {
    static var allTests: [(String, (HTTPSerializerTests) -> () throws -> Void)] {
        return [
            ("testSerializeBuffer", testSerializeBuffer),
            ("testSerializeReceiverStream", testSerializeReceiverStream),
           ("testSerializeSenderStream", testSerializeSenderStream),
        ]
    }
}
