import XCTest
import Quark

class CoroutineTests : XCTestCase {
    var sum: Int = 0

    func worker(count: Int, n: Int) {
        for _ in 0 ..< count {
            sum += n
            yield
        }
    }

    func testStackPreallocation() {
        preallocateCoroutineStacks(stackCount: 10, stackSize: 25000)
    }

    func testCo() {
        co(self.worker(count: 3, n: 7))
        co(self.worker(count: 1, n: 11))
        co(self.worker(count: 2, n: 5))
        nap(for: 100.milliseconds)
        XCTAssert(sum == 42)
    }

    func testStackdeallocationWorks() {
        for _ in 0 ..< 20 {
            after(50.milliseconds) {}
        }
        nap(for: 100.milliseconds)
    }

    func testWakeUp() {
        let deadline = 100.milliseconds.fromNow()
        wake(at: deadline)
        let diff = now() - deadline
        XCTAssert(diff > -200 && diff < 200)
    }

    func testNap() {
        let channel = Channel<Double>()

        func delay(duration: Double) {
            nap(for: duration)
            channel.send(duration)
        }

        co(delay(duration: 30.milliseconds))
        co(delay(duration: 40.milliseconds))
        co(delay(duration: 10.milliseconds))
        co(delay(duration: 20.milliseconds))

        XCTAssert(channel.receive() == 10.milliseconds)
        XCTAssert(channel.receive() == 20.milliseconds)
        XCTAssert(channel.receive() == 30.milliseconds)
        XCTAssert(channel.receive() == 40.milliseconds)
    }

    func testPollFileDescriptor() throws {
        var event: PollEvent
        var size: Int
        let fds = UnsafeMutablePointer<Int32>(allocatingCapacity: 2)
        let result = socketpair(AF_UNIX, SOCK_STREAM, 0, fds)
        XCTAssert(result == 0)

        event = try poll(fds[0], for: .writing)
        XCTAssert(event == .writing)

        event = try poll(fds[0], for: .writing, timingOut: 100.milliseconds.fromNow())
        XCTAssert(event == .writing)

        do {
            _ = try poll(fds[0], for: .reading, timingOut: 100.milliseconds.fromNow())
            XCTFail()
        } catch PollError.timeout {
            // yeah (:
        } catch {
            XCTFail()
        }

        size = send(fds[1], "A", 1, 0)
        XCTAssert(size == 1)
        event = try poll(fds[0], for: .writing)
        XCTAssert(event == .writing)

        event = try poll(fds[0], for: [.reading, .writing])
        XCTAssert(event == [.reading, .writing])

        var c: Int8 = 0
        size = recv(fds[0], &c, 1, 0)
        XCTAssert(size == 1)
        XCTAssert(c == 65)
    }
}
