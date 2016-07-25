import XCTest
@testable import QuarkTestSuite
@testable import VeniceTestSuite

XCTMain([
     testCase(QuarkTests.allTests),
     testCase(CoroutineTests.allTests),
     testCase(ChannelTests.allTests),
     testCase(FallibleChannelTests.allTests),
     testCase(SelectTests.allTests),
     testCase(TickerTests.allTests),
     testCase(TimerTests.allTests),
     testCase(IPTests.allTests),
     testCase(TCPTests.allTests),
])
