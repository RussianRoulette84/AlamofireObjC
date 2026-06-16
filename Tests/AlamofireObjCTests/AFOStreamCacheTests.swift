import XCTest
@testable import AlamofireObjC

/// Streaming (`AFODataStreamRequest.onStream`) and the cached-response handler — both had no
/// test before. Both run against the real local HTTP server.
final class AFOStreamCacheTests: XCTestCase {

    private var server: LocalHTTPServer!

    override func setUpWithError() throws {
        server = try LocalHTTPServer(tls: false)
        try server.start()
    }

    override func tearDown() {
        server.stop(); server = nil
        super.tearDown()
    }

    func testDataStreamDeliversBodyThenCompletes() {
        let session = AFOSession(configuration: .ephemeral, serverTrustManager: nil,
                                 interceptor: nil, redirectHandler: nil,
                                 cachedResponseHandler: nil, eventMonitor: nil)
        var received = Data()
        let exp = expectation(description: "stream")

        let request = session.streamRequest("http://localhost:\(server.port)/", method: .get, headers: nil)
        request.onStream { chunk, completed, error in
            if let chunk = chunk { received.append(chunk) }
            if completed {
                XCTAssertNil(error)
                XCTAssertFalse(received.isEmpty, "stream should deliver the body")
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 10)
    }

    func testCachedResponseHandlerIsConsulted() {
        server.cacheable = true
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 2_000_000, diskCapacity: 0, directory: nil)
        config.requestCachePolicy = .useProtocolCachePolicy

        let exp = expectation(description: "cache")
        exp.assertForOverFulfill = false
        let handler = AFOCachedResponseHandler { proposed in exp.fulfill(); return proposed }
        let session = AFOSession(configuration: config, serverTrustManager: nil,
                                 interceptor: nil, redirectHandler: nil,
                                 cachedResponseHandler: handler, eventMonitor: nil)

        session.request("http://localhost:\(server.port)/cacheme", method: .get, parameters: nil,
                        encoding: .URLDefault, headers: nil)
            .responseData { _ in }
        wait(for: [exp], timeout: 10)
    }
}
