import XCTest
@testable import Quark

class URITests : XCTestCase {
    func testParseFailure() {
        XCTAssertThrowsError(try URI(""))
        XCTAssertThrowsError(try URI("http"))
        XCTAssertThrowsError(try URI("http:/"))
        XCTAssertThrowsError(try URI("http://"))
        XCTAssertThrowsError(try URI("http://username@zewo.io"))
    }

    func testSmallURI() throws {
        let uri = try URI("http://zewo.io")
        XCTAssertEqual(uri.scheme, "http")
        XCTAssertEqual(uri.host, "zewo.io")
        XCTAssertEqual(uri.queryDictionary, [:])
        XCTAssertEqual(uri.queryComplexDictionary.count, 0)
    }

    func testComplexURI() throws {
        let uriString = "http://user%20name:pass%20word@www.example.com:80/dir/sub%20dir?par%20am=1&par%20am=2%203&par%20am=&par%20am&pan%20am#frag%20ment"
        let decodedURIString = "http://user name:pass word@www.example.com:80/dir/sub dir?par am=1&par am=2 3&par am=&par am&pan am#frag ment"
        let uri = try URI(uriString)

        XCTAssertEqual(uri.scheme, "http")
        XCTAssertEqual(uri.userInfo?.username, "user name")
        XCTAssertEqual(uri.userInfo?.password, "pass word")
        XCTAssertEqual(uri.host, "www.example.com")
        XCTAssertEqual(uri.port, 80)
        XCTAssertEqual(uri.path, "/dir/sub dir")
        XCTAssertEqual(uri.query, "par%20am=1&par%20am=2%203&par%20am=&par%20am&pan%20am")
        XCTAssertEqual(uri.queryDictionary, ["par am": "", "pan am": ""])
        let complexDictionary = uri.queryComplexDictionary
        guard let param = complexDictionary["par am"] else {
            return XCTFail("Key \"par am\" should exist.")
        }
        guard param.count == 4 else {
            return XCTFail("Param should have 4 elements.")
        }
        XCTAssertEqual(param[0], "1")
        XCTAssertEqual(param[1], "2 3")
        XCTAssertEqual(param[2], "")
        XCTAssertEqual(param[3], nil)
        guard let panam = complexDictionary["pan am"] else {
            return XCTFail("Key \"pan am\" should exist.")
        }
        XCTAssertEqual(panam[0], nil)
        XCTAssertEqual(uri.fragment, "frag ment")
        XCTAssertEqual(uri.percentEncoded(), uriString)
        XCTAssertEqual(String(uri), decodedURIString)
    }

    func testEquality() throws {
        let uri = try URI("http://zewo.io")
        XCTAssert(uri == uri)
        let userInfo = URI.UserInfo(username: "username", password: "password")
        XCTAssert(userInfo == userInfo)
    }

    func testQuery() {
        var uri = URI(path: "/")
        uri.queryDictionary["foo bar"] = "fuu baz"
        XCTAssertEqual(uri.query, "foo%20bar=fuu%20baz")
    }
}

extension URITests {
    static var allTests: [(String, (URITests) -> () throws -> Void)] {
        return [
           ("testComplexURI", testComplexURI),
        ]
    }
}
