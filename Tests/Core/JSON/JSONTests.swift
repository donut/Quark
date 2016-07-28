import XCTest
@testable import Quark

class JSONTests : XCTestCase {
    func testJSON() throws {
        let parser = JSONStructuredDataParser()
        let serializer = JSONStructuredDataSerializer(ordering: true)

        let data: C7.Data = "{\"array\":[true,-4.2,-1969,null,\"hey! 😊\"],\"boolean\":false,\"dictionaryOfEmptyStuff\":{\"emptyArray\":[],\"emptyDictionary\":{},\"emptyString\":\"\"},\"double\":4.2,\"integer\":1969,\"null\":null,\"string\":\"yoo! 😎\"}"

        let structuredData: StructuredData = [
            "array": [
                true,
                -4.2,
                -1969,
                nil,
                "hey! 😊",
            ],
            "boolean": false,
            "dictionaryOfEmptyStuff": [
                "emptyArray": [],
                "emptyDictionary": [:],
                "emptyString": ""
            ],
            "double": 4.2,
            "integer": 1969,
            "null": nil,
            "string": "yoo! 😎",
        ]

        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, structuredData)

        let serialized = try serializer.serialize(structuredData)
        XCTAssertEqual(serialized, data)
    }

    func testNumberWithExponent() throws {
        let parser = JSONStructuredDataParser()
        let data: C7.Data = "[1E3]"
        let structuredData: StructuredData = [1_000]
        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, structuredData)
    }

    func testNumberWithNegativeExponent() throws {
        let parser = JSONStructuredDataParser()
        let data: C7.Data = "[1E-3]"
        let structuredData: StructuredData = [1E-3]
        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, structuredData)
    }

    func testWhitespaces() throws {
        let parser = JSONStructuredDataParser()
        let data: C7.Data = "[ \n\t\r1 \n\t\r]"
        let structuredData: StructuredData = [1]
        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, structuredData)
    }

    func testNumberStartingWithZero() throws {
        let parser = JSONStructuredDataParser()
        let data: C7.Data = "[0001000]"
        let structuredData: StructuredData = [1000]
        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, structuredData)
    }

    func testEscapedSlash() throws {
        let parser = JSONStructuredDataParser()
        let serializer = JSONStructuredDataSerializer()

        let data: C7.Data = "{\"foo\":\"\\\"\"}"

        let structuredData: StructuredData = [
            "foo": "\""
        ]

        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, structuredData)

        let serialized = try serializer.serialize(structuredData)
        XCTAssertEqual(serialized, data)
    }

    func testSmallDictionary() throws {
        let parser = JSONStructuredDataParser()
        let serializer = JSONStructuredDataSerializer()

        let data: C7.Data = "{\"foo\":\"bar\",\"fuu\":\"baz\"}"

        let structuredData: StructuredData = [
            "foo": "bar",
            "fuu": "baz",
        ]

        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, structuredData)

        let serialized = try serializer.serialize(structuredData)
        XCTAssert(serialized == data || serialized == "{\"fuu\":\"baz\",\"foo\":\"bar\"}")
    }

    func testInvalidStructuredData() throws {
        let serializer = JSONStructuredDataSerializer()

        let structuredData: StructuredData = [
            "foo": .data("yo!")
        ]

        var called = false

        do {
            _ = try serializer.serialize(structuredData)
            XCTFail("Should've throwed error")
        } catch {
            called = true
        }
        
        XCTAssert(called)
    }

    func testEscapedEmoji() throws {
        let parser = JSONStructuredDataParser()
        let serializer = JSONStructuredDataSerializer()

        let data: C7.Data = "[\"\\ud83d\\ude0e\"]"
        let structuredData: StructuredData = ["😎"]

        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, structuredData)

        let serialized = try serializer.serialize(structuredData)
        XCTAssertEqual(serialized, "[\"😎\"]")
    }

    func testEscapedSymbol() throws {
        let parser = JSONStructuredDataParser()
        let serializer = JSONStructuredDataSerializer()

        let data: C7.Data = "[\"\\u221e\"]"
        let structuredData: StructuredData = ["∞"]

        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, structuredData)

        let serialized = try serializer.serialize(structuredData)
        XCTAssertEqual(serialized, "[\"∞\"]")

    }
}

extension JSONTests {
    static var allTests: [(String, (JSONTests) -> () throws -> Void)] {
        return [
            ("testJSON", testJSON),
        ]
    }
}
