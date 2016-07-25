import XCTest
@testable import QuarkTestSuite

XCTMain([
     testCase(QuarkTests.allTests),
     testCase(CoroutineTests.allTests),
])
