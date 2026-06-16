import XCTest
@testable import AlamofireObjC

final class AFOErgonomicsTests: XCTestCase {

    override func tearDown() { StubURLProtocol.reset(); super.tearDown() }

    func testErrorCodeAndStatusOnValidationFailure() {
        StubURLProtocol.handler = { req in TestSupport.jsonResponse(for: req, body: Data("{}".utf8), status: 500) }
        let session = TestSupport.stubbedSession()
        let exp = expectation(description: "code")

        session.request("https://example.com/x", method: .get, parameters: nil,
                        encoding: .URLDefault, headers: nil)
            .validate()
            .responseData { response in
                XCTAssertEqual(response.error?.afoErrorCode, .responseValidationFailed)
                XCTAssertEqual(response.error?.afoStatusCode, 500)
                XCTAssertFalse(response.error?.afoIsCancelled ?? true)
                exp.fulfill()
            }
        wait(for: [exp], timeout: 5)
    }

    func testTypedResponseAccessors() {
        StubURLProtocol.handler = { req in TestSupport.jsonResponse(for: req, body: #"{"name":"Yaro"}"#.data(using: .utf8)!) }
        let session = TestSupport.stubbedSession()
        let exp = expectation(description: "accessors")

        session.request("https://example.com/x", method: .get, parameters: nil,
                        encoding: .URLDefault, headers: nil)
            .responseJSON { response in
                XCTAssertEqual(response.jsonDictionary?["name"] as? String, "Yaro")
                XCTAssertNil(response.jsonArray)
                XCTAssertEqual(response.stringValue, #"{"name":"Yaro"}"#)
                XCTAssertEqual(response.dataValue, #"{"name":"Yaro"}"#.data(using: .utf8))
                exp.fulfill()
            }
        wait(for: [exp], timeout: 5)
    }

    func testResponseObjectMapsModel() {
        StubURLProtocol.handler = { req in TestSupport.jsonResponse(for: req, body: #"{"name":"Yaro"}"#.data(using: .utf8)!) }
        let session = TestSupport.stubbedSession()
        let exp = expectation(description: "model")

        session.request("https://example.com/x", method: .get, parameters: nil,
                        encoding: .URLDefault, headers: nil)
            .responseObject(map: { json in (json as? [String: Any])?["name"] },
                            handler: { model, response in
                                XCTAssertEqual(model as? String, "Yaro")
                                XCTAssertTrue(response.isSuccess)
                                exp.fulfill()
                            })
        wait(for: [exp], timeout: 5)
    }

    func testPerRequestInterceptorInjectsHeader() {
        StubURLProtocol.handler = { req in TestSupport.jsonResponse(for: req, body: Data("{}".utf8)) }
        let session = TestSupport.stubbedSession()
        let exp = expectation(description: "per-request")

        session.request("https://example.com/x", method: .get, parameters: nil, encoding: .URLDefault,
                        headers: nil, timeout: 0, interceptor: .headerInjector("X-Per", value: "1"))
            .responseData { _ in
                XCTAssertEqual(StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "X-Per"), "1")
                exp.fulfill()
            }
        wait(for: [exp], timeout: 5)
    }

    func testUnderlyingErrorIsCarried() {
        StubURLProtocol.handler = { _ in throw URLError(.cannotConnectToHost) }
        let session = TestSupport.stubbedSession()
        let exp = expectation(description: "underlying")

        session.request("https://example.com/dead", method: .get, parameters: nil,
                        encoding: .URLDefault, headers: nil)
            .responseData { response in
                XCTAssertEqual(response.error?.afoErrorCode, .sessionTaskFailed)
                XCTAssertNotNil(response.error?.afoUnderlyingError, "transport error should be carried")
                exp.fulfill()
            }
        wait(for: [exp], timeout: 5)
    }

    func testCancelAllRequestsDoesNotCrash() {
        let session = TestSupport.stubbedSession()
        session.cancelAllRequests()   // no in-flight requests; must be safe
    }
}
