import XCTest
@testable import AlamofireObjC

/// HTTP Basic auth via NSURLCredential, against a real TLS server that issues a 401 challenge.
final class AFOAuthTests: XCTestCase {

    private var server: LocalHTTPServer!

    override func setUpWithError() throws {
        server = try LocalHTTPServer(tls: true)
        server.basicAuthCredentials = (user: "yaro", password: "secret")
        try server.start()
    }

    override func tearDown() {
        server.stop()
        server = nil
        super.tearDown()
    }

    /// Disabled evaluator so the self-signed TLS is trusted — this test is about auth, not pinning.
    private func session() -> AFOSession {
        let trust = AFOServerTrustManager(policies: ["localhost": .disabled()], allHostsMustBeEvaluated: true)
        return AFOSession(configuration: .ephemeral, serverTrustManager: trust,
                          interceptor: nil, redirectHandler: nil,
                          cachedResponseHandler: nil, eventMonitor: nil)
    }

    func testRequestWithoutCredentialsGets401() {
        let exp = expectation(description: "401")
        let session = session()
        session.request("https://localhost:\(server.port)/", method: .get, parameters: nil,
                        encoding: .URLDefault, headers: nil)
            .validate()
            .responseData { response in
                XCTAssertNotNil(response.error)
                XCTAssertEqual(response.statusCode, 401)
                exp.fulfill()
            }
        wait(for: [exp], timeout: 10)
    }

    func testRequestWithCredentialSucceeds() {
        let exp = expectation(description: "authed")
        let credential = URLCredential(user: "yaro", password: "secret", persistence: .forSession)
        let session = session()
        session.request("https://localhost:\(server.port)/", method: .get, parameters: nil,
                        encoding: .URLDefault, headers: nil)
            .authenticateWithCredential(credential)
            .validate()
            .responseJSON { response in
                XCTAssertNil(response.error, "expected auth success, got \(String(describing: response.error))")
                XCTAssertEqual((response.value as? [String: Any])?["ok"] as? Bool, true)
                exp.fulfill()
            }
        wait(for: [exp], timeout: 10)
    }
}
