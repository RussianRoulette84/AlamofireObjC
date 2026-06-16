import XCTest
@testable import AlamofireObjC

final class AFOFeatureTests: XCTestCase {

    override func tearDown() { StubURLProtocol.reset(); super.tearDown() }

    /// #1 — a proper serializer treats an allowed empty body (204) as NSNull, not an error.
    func testEmptyResponseYieldsNullNotError() {
        StubURLProtocol.handler = { req in
            let response = HTTPURLResponse(url: req.url!, statusCode: 204, httpVersion: "HTTP/1.1",
                                           headerFields: nil)!
            return (response, nil)
        }
        let session = TestSupport.stubbedSession()
        let exp = expectation(description: "empty")

        session.request("https://example.com/no-content", method: .get, parameters: nil,
                        encoding: .URLDefault, headers: nil)
            .responseJSON { response in
                XCTAssertNil(response.error)
                XCTAssertTrue(response.value is NSNull)
                exp.fulfill()
            }
        wait(for: [exp], timeout: 5)
    }

    /// #17 — RetryPolicy retries a retryable failure on an idempotent method until it succeeds.
    func testRetryPolicyRetriesUntilSuccess() {
        let attempts = Counter()
        StubURLProtocol.handler = { req in
            if attempts.increment() < 3 { throw URLError(.networkConnectionLost) }
            return TestSupport.jsonResponse(for: req, body: Data("{}".utf8))
        }
        let session = AFOSession(configuration: StubURLProtocol.configuration(),
                                 serverTrustManager: nil, interceptor: nil,
                                 retryPolicy: AFORetryPolicy(retryLimit: 3, exponentialBackoffBase: 2,
                                                             exponentialBackoffScale: 0.01),
                                 redirectHandler: nil, cachedResponseHandler: nil, eventMonitor: nil)
        let exp = expectation(description: "retry")

        session.request("https://example.com/flaky", method: .get, parameters: nil,
                        encoding: .URLDefault, headers: nil)
            .responseData { response in
                XCTAssertNil(response.error)
                XCTAssertEqual(attempts.count, 3)
                exp.fulfill()
            }
        wait(for: [exp], timeout: 10)
    }

    private final class Counter {
        private let lock = NSLock()
        private var _count = 0
        var count: Int { lock.lock(); defer { lock.unlock() }; return _count }
        func increment() -> Int { lock.lock(); defer { lock.unlock() }; _count += 1; return _count }
    }
}
