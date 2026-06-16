import XCTest
@testable import AlamofireObjC

final class AFOValidationContentTypeTests: XCTestCase {

    override func tearDown() { StubURLProtocol.reset(); super.tearDown() }

    func testContentTypeValidationFailsForWrongType() {
        StubURLProtocol.handler = { req in
            let response = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: "HTTP/1.1",
                                           headerFields: ["Content-Type": "text/plain"])!
            return (response, Data("plain".utf8))
        }
        let session = TestSupport.stubbedSession()
        let exp = expectation(description: "ctype")

        let config = AFOValidationConfig(statusCodes: nil, contentTypes: ["application/json"])
        session.request("https://example.com/x", method: .get, parameters: nil,
                        encoding: .URLDefault, headers: nil)
            .validateWithConfig(config)
            .responseData { response in
                XCTAssertNotNil(response.error, "text/plain should fail application/json validation")
                exp.fulfill()
            }
        wait(for: [exp], timeout: 5)
    }

    func testStatusRangeValidationPasses() {
        StubURLProtocol.handler = { req in
            let response = HTTPURLResponse(url: req.url!, statusCode: 201, httpVersion: "HTTP/1.1",
                                           headerFields: nil)!
            return (response, Data("{}".utf8))
        }
        let session = TestSupport.stubbedSession()
        let exp = expectation(description: "status range")

        let config = AFOValidationConfig.config(fromStatus: 200, toStatus: 300)
        session.request("https://example.com/x", method: .get, parameters: nil,
                        encoding: .URLDefault, headers: nil)
            .validateWithConfig(config)
            .responseData { response in
                XCTAssertNil(response.error)
                exp.fulfill()
            }
        wait(for: [exp], timeout: 5)
    }
}
