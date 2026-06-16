import XCTest
@testable import AlamofireObjC

/// #11 — integration coverage against the real local server: redirect handling and the
/// event monitor lifecycle.
final class AFOIntegrationTests: XCTestCase {

    private var server: LocalHTTPServer!

    override func setUpWithError() throws {
        server = try LocalHTTPServer(tls: false)
        try server.start()
    }

    override func tearDown() {
        server.stop()
        server = nil
        super.tearDown()
    }

    func testRedirectHandlerIsConsultedAndCanRefuse() {
        server.redirectTo = "http://localhost:\(server.port)/elsewhere"
        var handlerCalled = false
        let handler = AFORedirectHandler { _, _ in
            handlerCalled = true
            return nil   // refuse to follow → the 302 becomes the final response
        }
        let session = AFOSession(configuration: .ephemeral, serverTrustManager: nil,
                                 interceptor: nil, redirectHandler: handler,
                                 cachedResponseHandler: nil, eventMonitor: nil)
        let exp = expectation(description: "redirect")

        session.request("http://localhost:\(server.port)/start", method: .get, parameters: nil,
                        encoding: .URLDefault, headers: nil)
            .responseData { response in
                XCTAssertTrue(handlerCalled, "redirect handler should be consulted")
                XCTAssertEqual(response.statusCode, 302)
                exp.fulfill()
            }
        wait(for: [exp], timeout: 10)
    }

    func testRedirectHandlerCanFollow() {
        server.redirectOnlyPath = "/start"
        server.redirectTo = "http://localhost:\(server.port)/end"
        let handler = AFORedirectHandler { request, _ in request }   // follow it
        let session = AFOSession(configuration: .ephemeral, serverTrustManager: nil,
                                 interceptor: nil, redirectHandler: handler,
                                 cachedResponseHandler: nil, eventMonitor: nil)
        let exp = expectation(description: "follow")
        session.request("http://localhost:\(server.port)/start", method: .get, parameters: nil,
                        encoding: .URLDefault, headers: nil)
            .responseData { response in
                XCTAssertNil(response.error)
                XCTAssertEqual(response.statusCode, 200, "followed redirect should land on /end → 200")
                exp.fulfill()
            }
        wait(for: [exp], timeout: 10)
    }

    func testEventMonitorTaskAndCURLFire() {
        let monitor = AFOEventMonitor()
        let created = expectation(description: "task")
        let curl = expectation(description: "curl")
        created.assertForOverFulfill = false
        curl.assertForOverFulfill = false
        monitor.didCreateTask = { _ in created.fulfill() }
        monitor.didResolveCURL = { string in
            XCTAssertTrue(string.contains("curl"))
            curl.fulfill()
        }
        let session = AFOSession(configuration: .ephemeral, serverTrustManager: nil,
                                 interceptor: nil, redirectHandler: nil,
                                 cachedResponseHandler: nil, eventMonitor: monitor)
        session.request("http://localhost:\(server.port)/", method: .get, parameters: nil,
                        encoding: .URLDefault, headers: nil)
            .responseData { _ in }
        wait(for: [created, curl], timeout: 10)
    }

    func testEventMonitorReceivesLifecycle() {
        let monitor = AFOEventMonitor()
        let exp = expectation(description: "finished")
        exp.assertForOverFulfill = false
        monitor.didFinishRequest = { _, response, _ in
            XCTAssertEqual(response?.statusCode, 200)
            exp.fulfill()
        }
        let session = AFOSession(configuration: .ephemeral, serverTrustManager: nil,
                                 interceptor: nil, redirectHandler: nil,
                                 cachedResponseHandler: nil, eventMonitor: monitor)

        session.request("http://localhost:\(server.port)/x", method: .get, parameters: nil,
                        encoding: .URLDefault, headers: nil)
            .responseData { _ in }
        wait(for: [exp], timeout: 10)
    }
}
