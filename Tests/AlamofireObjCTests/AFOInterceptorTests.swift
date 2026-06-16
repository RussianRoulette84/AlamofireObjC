import XCTest
@testable import AlamofireObjC

final class AFOInterceptorTests: XCTestCase {

    override func tearDown() { StubURLProtocol.reset(); super.tearDown() }

    private func session(interceptor: AFOInterceptor) -> AFOSession {
        AFOSession(configuration: StubURLProtocol.configuration(),
                   serverTrustManager: nil, interceptor: interceptor,
                   redirectHandler: nil, cachedResponseHandler: nil, eventMonitor: nil)
    }

    func testAdapterInjectsHeader() {
        StubURLProtocol.handler = { req in TestSupport.jsonResponse(for: req, body: Data("{}".utf8)) }
        let interceptor = AFOInterceptor.headerInjector("X-Injected", value: "yes")
        let exp = expectation(description: "adapter")

        let session = session(interceptor: interceptor)
        session.request("https://example.com/x", method: .get, parameters: nil, encoding: .URLDefault, headers: nil)
            .responseData { _ in
                XCTAssertEqual(StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "X-Injected"), "yes")
                exp.fulfill()
            }
        wait(for: [exp], timeout: 5)
    }

    func testRetrierRetriesUntilSuccess() {
        let attempts = Attempts()
        StubURLProtocol.handler = { req in
            let n = attempts.increment()
            if n < 3 { throw URLError(.networkConnectionLost) }
            return TestSupport.jsonResponse(for: req, body: Data("{}".utf8))
        }
        let interceptor = AFOInterceptor()
        interceptor.retrierBlock = { _, retryCount in
            retryCount < 2 ? AFORetryDecision.retry() : AFORetryDecision.doNotRetry()
        }
        let exp = expectation(description: "retry")

        let session = session(interceptor: interceptor)
        session.request("https://example.com/flaky", method: .get, parameters: nil, encoding: .URLDefault, headers: nil)
            .responseData { response in
                XCTAssertNil(response.error)
                XCTAssertEqual(attempts.count, 3, "should fail twice then succeed")
                exp.fulfill()
            }
        wait(for: [exp], timeout: 5)
    }

    /// Thread-safe attempt counter for the stub handler.
    private final class Attempts {
        private let lock = NSLock()
        private var _count = 0
        var count: Int { lock.lock(); defer { lock.unlock() }; return _count }
        func increment() -> Int { lock.lock(); defer { lock.unlock() }; _count += 1; return _count }
    }
}
