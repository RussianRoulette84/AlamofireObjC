import XCTest
@testable import AlamofireObjC

final class AFOSessionTests: XCTestCase {

    override func tearDown() {
        StubURLProtocol.reset()
        super.tearDown()
    }

    func testGETReturnsParsedJSON() {
        StubURLProtocol.handler = { req in
            TestSupport.jsonResponse(for: req, body: #"{"name":"Yaro"}"#.data(using: .utf8)!)
        }
        let session = TestSupport.stubbedSession()
        let expectation = expectation(description: "json")

        session.request("https://example.com/me", method: .get, parameters: nil,
                        encoding: .URLDefault, headers: nil)
            .responseJSON { response in
                XCTAssertNil(response.error)
                XCTAssertEqual((response.value as? [String: Any])?["name"] as? String, "Yaro")
                XCTAssertEqual(response.statusCode, 200)
                expectation.fulfill()
            }
        wait(for: [expectation], timeout: 5)
    }

    func testNullStrippingRemovesNSNull() {
        StubURLProtocol.handler = { req in
            TestSupport.jsonResponse(for: req, body: #"{"a":1,"b":null}"#.data(using: .utf8)!)
        }
        let session = TestSupport.stubbedSession()
        let expectation = expectation(description: "strip")

        let request = session.request("https://example.com/x", method: .get, parameters: nil,
                                      encoding: .URLDefault, headers: nil)
        request.removesKeysWithNullValues = true
        request.responseJSON { response in
            let dict = response.value as? [String: Any]
            XCTAssertNotNil(dict?["a"])
            XCTAssertNil(dict?["b"], "null value should be stripped")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
    }

    func testValidationFailureProducesError() {
        StubURLProtocol.handler = { req in
            TestSupport.jsonResponse(for: req, body: Data("nope".utf8), status: 500)
        }
        let session = TestSupport.stubbedSession()
        let expectation = expectation(description: "fail")

        session.request("https://example.com/boom", method: .get, parameters: nil,
                        encoding: .URLDefault, headers: nil)
            .validate()
            .responseJSON { response in
                XCTAssertNotNil(response.error)
                XCTAssertEqual(response.error?.userInfo[AFOError.statusCodeKey] as? Int, 500)
                expectation.fulfill()
            }
        wait(for: [expectation], timeout: 5)
    }

    func testPOSTSendsJSONBody() {
        StubURLProtocol.handler = { req in
            TestSupport.jsonResponse(for: req, body: Data("{}".utf8))
        }
        let session = TestSupport.stubbedSession()
        let expectation = expectation(description: "post")

        session.request("https://example.com/create", method: .post,
                        parameters: ["title": "Pin"], encoding: .JSON, headers: nil)
            .responseJSON { _ in
                let sent = StubURLProtocol.lastBody.flatMap { try? JSONSerialization.jsonObject(with: $0) }
                XCTAssertEqual((sent as? [String: Any])?["title"] as? String, "Pin")
                expectation.fulfill()
            }
        wait(for: [expectation], timeout: 5)
    }
}
