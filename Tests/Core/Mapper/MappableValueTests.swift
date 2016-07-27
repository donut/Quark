import XCTest
@testable import Quark

class MappableValueTests : XCTestCase {
    func testNestedMappable() throws {
        struct Test: Mappable {
            let nest: Nested
            init(mapper: Mapper) throws {
                try self.nest = mapper.map(from: "nest")
            }
        }
        struct Nested: Mappable {
            let string: String
            init(mapper: Mapper) throws {
                try self.string = mapper.map(from: "string")
            }
        }
        let structuredData: StructuredData = [
            "nest": ["string": "hello"]
        ]
        let test = try Test(mapper: Mapper(structuredData: structuredData))
        XCTAssertEqual(test.nest.string, "hello")
    }

    func testNestedInvalidMappable() {
        struct Nested: Mappable {
            let string: String
            init(mapper: Mapper) throws {
                try self.string = mapper.map(from: "string")
            }
        }
        struct Test: Mappable {
            let nested: Nested
            init(mapper: Mapper) throws {
                try self.nested = mapper.map(from: "nest")
            }
        }
        let structuredData: StructuredData = ["nest": ["strong": "er"]]
        let test = try? Test(mapper: Mapper(structuredData: structuredData))
        XCTAssertNil(test)
    }

    func testNestedOptionalMappable() throws {
        // struct Nested: Mappable {
        //     let string: String
        //     init(mapper: Mapper) throws {
        //         try self.string = mapper.map(from: "string")
        //     }
        // }
        // struct Test: Mappable {
        //     let nested: Nested?
        //     init(mapper: Mapper) throws {
        //         self.nested = mapper.map(optionalFrom: "nest")
        //     }
        // }
        // let structuredData: StructuredData = ["nest": ["string": "zewo"]]
        // let test = try Test(mapper: Mapper(structuredData: structuredData))
        // XCTAssertEqual(test.nested?.string, "zewo")
    }

    func testNestedOptionalInvalidMappable() throws {
        struct Nested: Mappable {
            let string: String
            init(mapper: Mapper) throws {
                try self.string = mapper.map(from: "string")
            }
        }
        struct Test: Mappable {
            let nested: Nested?
            init(mapper: Mapper) throws {
                self.nested = mapper.map(optionalFrom: "nest")
            }
        }
        let structuredData: StructuredData = ["nest": ["strong": "er"]]
        let test = try Test(mapper: Mapper(structuredData: structuredData))
        XCTAssertNil(test.nested)
    }

    func testArrayOfMappables() throws {
        // struct Nested: Mappable {
        //     let string: String
        //     init(mapper: Mapper) throws {
        //         try self.string = mapper.map(from: "string")
        //     }
        // }
        // struct Test: Mappable {
        //     let nested: [Nested]
        //     init(mapper: Mapper) throws {
        //         try self.nested = mapper.map(arrayFrom: "nested")
        //     }
        // }
        // let test = try Test(mapper: Mapper(structuredData: ["nested": [["string": "fire"], ["string": "sun"]]]))
        // XCTAssertEqual(test.nested.count, 2)
        // XCTAssertEqual(test.nested[1].string, "sun")
    }

    func testArrayOfInvalidMappables() throws {
        // struct Nested: Mappable {
        //     let string: String
        //     init(mapper: Mapper) throws {
        //         try self.string = mapper.map(from: "string")
        //     }
        // }
        // struct Test: Mappable {
        //     let nested: [Nested]
        //     init(mapper: Mapper) throws {
        //         try self.nested = mapper.map(arrayFrom: "nested")
        //     }
        // }
        // let test = try Test(mapper: Mapper(structuredData: ["nested": [["string": 1], ["string": 1]]]))
        // XCTAssertTrue(test.nested.isEmpty)
    }

    func testInvalidArrayOfMappables() {
        struct Nested: Mappable {
            let string: String
            init(mapper: Mapper) throws {
                try self.string = mapper.map(from: "string")
            }
        }
        struct Test: Mappable {
            let nested: [Nested]
            init(mapper: Mapper) throws {
                try self.nested = mapper.map(arrayFrom: "nested")
            }
        }
        let test = try? Test(mapper: Mapper(structuredData: ["hested": [["strong": "fire"], ["strong": "sun"]]]))
        XCTAssertNil(test)
    }

    func testArrayOfPartiallyInvalidMappables() throws {
        // struct Nested: Mappable {
        //     let string: String
        //     init(mapper: Mapper) throws {
        //         try self.string = mapper.map(from: "string")
        //     }
        // }
        // struct Test: Mappable {
        //     let nested: [Nested]
        //     init(mapper: Mapper) throws {
        //         try self.nested = mapper.map(arrayFrom: "nested")
        //     }
        // }
        // let test = try Test(mapper: Mapper(structuredData: ["nested": [["string": 1], ["string": "fire"]]]))
        // XCTAssertEqual(test.nested.count, 1)
    }

    func testExistingOptionalArrayOfMappables() throws {
        // struct Nested: Mappable {
        //     let string: String
        //     init(mapper: Mapper) throws {
        //         try self.string = mapper.map(from: "string")
        //     }
        // }
        // struct Test: Mappable {
        //     let nested: [Nested]?
        //     init(mapper: Mapper) throws {
        //         self.nested = mapper.map(optionalArrayFrom: "nested")
        //     }
        // }
        // let test = try Test(mapper: Mapper(structuredData: ["nested": [["string": "ring"], ["string": "fire"]]]))
        // XCTAssertEqual(test.nested?.count, 2)
    }

    func testOptionalArrayOfMappables() throws {
        struct Nested: Mappable {
            let string: String
            init(mapper: Mapper) throws {
                try self.string = mapper.map(from: "string")
            }
        }
        struct Test: Mappable {
            let nested: [Nested]?
            init(mapper: Mapper) throws {
                self.nested = mapper.map(optionalArrayFrom: "nested")
            }
        }
        let test = try Test(mapper: Mapper(structuredData: []))
        XCTAssertNil(test.nested)
    }

    func testOptionalArrayOfInvalidMappables() throws {
        // struct Nested: Mappable {
        //     let string: String
        //     init(mapper: Mapper) throws {
        //         try self.string = mapper.map(from: "string")
        //     }
        // }
        // struct Test: Mappable {
        //     let nested: [Nested]?
        //     init(mapper: Mapper) throws {
        //         self.nested = mapper.map(optionalArrayFrom: "nested")
        //     }
        // }
        // let test = try Test(mapper: Mapper(structuredData: ["nested": [["strong": 3], ["strong": 5]]]))
        // XCTAssertEqual(test.nested?.count, 0)
    }

    func testOptionalArrayOfPartiallyInvalidMappables() throws {
        struct Nested: Mappable {
            let string: String
            init(mapper: Mapper) throws {
                try self.string = mapper.map(from: "string")
            }
        }
        struct Test: Mappable {
            let nested: [Nested]?
            init(mapper: Mapper) throws {
                self.nested = mapper.map(optionalArrayFrom: "nested")
            }
        }
        let test = try Test(mapper: Mapper(structuredData: ["nested": [["string": 1], ["string": "fire"]]]))
        XCTAssertEqual(test.nested?.count, 1)
    }
}

extension MappableValueTests {
    static var allTests: [(String, (MappableValueTests) -> () throws -> Void)] {
        return [
            ("testNestedMappable", testNestedMappable),
            ("testNestedInvalidMappable", testNestedInvalidMappable),
            ("testNestedOptionalMappable", testNestedOptionalMappable),
            ("testNestedOptionalInvalidMappable", testNestedOptionalInvalidMappable),
            ("testArrayOfMappables", testArrayOfMappables),
            ("testArrayOfInvalidMappables", testArrayOfInvalidMappables),
            ("testInvalidArrayOfMappables", testInvalidArrayOfMappables),
            ("testArrayOfPartiallyInvalidMappables", testArrayOfPartiallyInvalidMappables),
            ("testExistingOptionalArrayOfMappables", testExistingOptionalArrayOfMappables),
            ("testOptionalArrayOfMappables", testOptionalArrayOfMappables),
            ("testOptionalArrayOfInvalidMappables", testOptionalArrayOfInvalidMappables),
            ("testOptionalArrayOfPartiallyInvalidMappables", testOptionalArrayOfPartiallyInvalidMappables)
        ]
    }
}
