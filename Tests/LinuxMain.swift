import XCTest
@testable import QuarkTestSuite
@testable import VeniceTestSuite
@testable import HTTPTestSuite
@testable import CoreTestSuite

XCTMain([
    // Quark
    testCase(QuarkTests.allTests),
    // Venice
    testCase(CoroutineTests.allTests),
    testCase(ChannelTests.allTests),
    testCase(FallibleChannelTests.allTests),
    testCase(SelectTests.allTests),
    testCase(TickerTests.allTests),
    testCase(TimerTests.allTests),
    testCase(IPTests.allTests),
    testCase(TCPTests.allTests),
    // HTTP
    testCase(RoutesTests.allTests),
    // Core
    testCase(InternalTests.allTests),
    testCase(MappableTests.allTests),
    testCase(PerformanceTests.allTests),
    testCase(PublicTests.allTests),
])
