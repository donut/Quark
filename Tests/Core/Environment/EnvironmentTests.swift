import XCTest
@testable import Quark

class EnvironmentTests : XCTestCase {
    func testEnvironment() throws {
        environment["foo"] = "bar"
        XCTAssertEqual(environment["foo"], "bar")
        XCTAssertTrue(environment.variables.contains({$0 == "foo" && $1 == "bar"}))
        environment.set(value: "baz", to: "foo", replace: false)
        XCTAssertEqual(environment["foo"], "bar")
        environment["foo"] = nil
        XCTAssertNil(environment["foo"])

        print(buildConfiguration)
    }
}

extension EnvironmentTests {
    static var allTests : [(String, (EnvironmentTests) -> () throws -> Void)] {
        return [
            ("testEnvironment", testEnvironment),
        ]
    }
}
