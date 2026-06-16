import XCTest
@testable import AlamofireObjC

final class AFOEncodingTests: XCTestCase {

    override func tearDown() { StubURLProtocol.reset(); super.tearDown() }

    func testURLEncodingPutsParamsInQueryForGET() {
        StubURLProtocol.handler = { req in TestSupport.jsonResponse(for: req, body: Data("{}".utf8)) }
        let session = TestSupport.stubbedSession()
        let exp = expectation(description: "url")

        session.request("https://example.com/search", method: .get,
                        parameters: ["q": "pin"], encoding: .URLDefault, headers: nil)
            .responseJSON { _ in
                XCTAssertEqual(StubURLProtocol.lastRequest?.url?.query, "q=pin")
                exp.fulfill()
            }
        wait(for: [exp], timeout: 5)
    }

    func testJSONEncodingSetsContentType() {
        StubURLProtocol.handler = { req in TestSupport.jsonResponse(for: req, body: Data("{}".utf8)) }
        let session = TestSupport.stubbedSession()
        let exp = expectation(description: "json")

        session.request("https://example.com/x", method: .post,
                        parameters: ["a": 1], encoding: .JSON, headers: nil)
            .responseJSON { _ in
                let type = StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "Content-Type")
                XCTAssertEqual(type, "application/json")
                exp.fulfill()
            }
        wait(for: [exp], timeout: 5)
    }

    func testHTTPMethodBridgeRoundTrips() {
        XCTAssertEqual(AFOHTTPMethodBridge.string(from: .post), "POST")
        XCTAssertEqual(AFOHTTPMethodBridge.method(fromString: "delete"), .delete)
    }
}
