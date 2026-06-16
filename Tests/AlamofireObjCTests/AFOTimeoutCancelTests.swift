import XCTest
@testable import AlamofireObjC

/// Per-request timeout (#6) and `cancelAllRequests` (#10) — both run against a server that
/// delays its response so the request is genuinely in flight.
final class AFOTimeoutCancelTests: XCTestCase {

    private var server: LocalHTTPServer!

    override func setUpWithError() throws {
        server = try LocalHTTPServer(tls: false)
        server.responseDelay = 3   // respond only after 3s
        try server.start()
    }

    override func tearDown() {
        server.stop(); server = nil
        super.tearDown()
    }

    private func session() -> AFOSession {
        AFOSession(configuration: .ephemeral, serverTrustManager: nil, interceptor: nil,
                   redirectHandler: nil, cachedResponseHandler: nil, eventMonitor: nil)
    }

    func testPerRequestTimeoutFires() {
        let session = session()
        let exp = expectation(description: "timeout")
        session.request("http://localhost:\(server.port)/", method: .get, parameters: nil,
                        encoding: .URLDefault, headers: nil, timeout: 0.5, interceptor: nil)
            .responseData { response in
                XCTAssertNotNil(response.error, "0.5s timeout vs 3s delay should fail")
                XCTAssertEqual(response.error?.afoErrorCode, .sessionTaskFailed)
                exp.fulfill()
            }
        wait(for: [exp], timeout: 10)
    }

    func testCancelAllRequestsCancelsInFlight() {
        let session = session()
        let exp = expectation(description: "cancel")
        session.request("http://localhost:\(server.port)/", method: .get, parameters: nil,
                        encoding: .URLDefault, headers: nil)
            .responseData { response in
                XCTAssertNotNil(response.error)
                XCTAssertTrue(response.error?.afoIsCancelled ?? false, "should be an explicit cancel")
                exp.fulfill()
            }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { session.cancelAllRequests() }
        wait(for: [exp], timeout: 10)
    }
}
