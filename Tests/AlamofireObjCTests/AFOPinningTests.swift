import XCTest
@testable import AlamofireObjC

/// Certificate / public-key pinning, exercised against a real self-signed TLS server.
final class AFOPinningTests: XCTestCase {

    private var server: LocalHTTPServer!

    override func setUpWithError() throws {
        server = try LocalHTTPServer(tls: true)
        try server.start()
    }

    override func tearDown() {
        server.stop()
        server = nil
        super.tearDown()
    }

    private func session(policy: AFOServerTrustPolicy) -> AFOSession {
        let trust = AFOServerTrustManager(policies: ["localhost": policy], allHostsMustBeEvaluated: true)
        return AFOSession(configuration: .ephemeral,
                          serverTrustManager: trust,
                          interceptor: nil, redirectHandler: nil,
                          cachedResponseHandler: nil, eventMonitor: nil)
    }

    private func request(_ session: AFOSession, expectSuccess: Bool, _ message: String) {
        let exp = expectation(description: message)
        session.request("https://localhost:\(server.port)/", method: .get, parameters: nil,
                        encoding: .URLDefault, headers: nil)
            .responseData { response in
                if expectSuccess {
                    XCTAssertNil(response.error, "\(message): expected success, got \(String(describing: response.error))")
                } else {
                    XCTAssertNotNil(response.error, "\(message): expected pinning failure")
                }
                exp.fulfill()
            }
        wait(for: [exp], timeout: 10)
    }

    func testCertificatePinningSucceedsForMatchingCert() {
        let policy = AFOServerTrustPolicy.pinnedCertificates([TestCertificates.der(named: "server")],
                                                             acceptSelfSigned: true,
                                                             performDefaultValidation: false,
                                                             validateHost: true)
        request(session(policy: policy), expectSuccess: true, "matching cert")
    }

    func testCertificatePinningFailsForMismatchedCert() {
        let policy = AFOServerTrustPolicy.pinnedCertificates([TestCertificates.der(named: "other")],
                                                             acceptSelfSigned: true,
                                                             performDefaultValidation: false,
                                                             validateHost: true)
        request(session(policy: policy), expectSuccess: false, "mismatched cert")
    }

    func testPublicKeyPinningSucceedsForMatchingKey() {
        // Pure key-pinning: a self-signed leaf has no trusted anchor, so host/default trust
        // eval would fail with "root not trusted". Match on the public key alone.
        let policy = AFOServerTrustPolicy.pinnedPublicKeys(fromDERCertificates: [TestCertificates.der(named: "server")],
                                                           performDefaultValidation: false,
                                                           validateHost: false)
        request(session(policy: policy), expectSuccess: true, "matching public key")
    }

    func testDisabledEvaluatorAcceptsAnyCertificate() {
        request(session(policy: .disabled()), expectSuccess: true, "disabled evaluator")
    }
}
