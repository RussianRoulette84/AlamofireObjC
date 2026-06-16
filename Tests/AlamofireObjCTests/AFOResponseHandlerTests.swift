import XCTest
@testable import AlamofireObjC

final class AFOResponseHandlerTests: XCTestCase {

    override func tearDown() { StubURLProtocol.reset(); super.tearDown() }

    func testResponseDataDeliversRawBytes() {
        let body = Data("hello".utf8)
        StubURLProtocol.handler = { req in TestSupport.jsonResponse(for: req, body: body) }
        let session = TestSupport.stubbedSession()
        let exp = expectation(description: "data")

        session.request("https://example.com/x", method: .get, parameters: nil,
                        encoding: .URLDefault, headers: nil)
            .responseData { response in
                XCTAssertEqual(response.value as? Data, body)
                XCTAssertEqual(response.data, body)
                exp.fulfill()
            }
        wait(for: [exp], timeout: 5)
    }

    func testResponseStringDecodesBody() {
        StubURLProtocol.handler = { req in TestSupport.jsonResponse(for: req, body: Data("plain text".utf8)) }
        let session = TestSupport.stubbedSession()
        let exp = expectation(description: "string")

        session.request("https://example.com/x", method: .get, parameters: nil,
                        encoding: .URLDefault, headers: nil)
            .responseString { response in
                XCTAssertEqual(response.value as? String, "plain text")
                exp.fulfill()
            }
        wait(for: [exp], timeout: 5)
    }

    func testResponseFieldsArePopulated() {
        StubURLProtocol.handler = { req in TestSupport.jsonResponse(for: req, body: Data("{}".utf8)) }
        let session = TestSupport.stubbedSession()
        let exp = expectation(description: "fields")

        session.request("https://example.com/path", method: .get, parameters: nil,
                        encoding: .URLDefault, headers: nil)
            .responseData { response in
                XCTAssertEqual(response.request?.url?.path, "/path")
                XCTAssertNotNil(response.response)
                XCTAssertEqual(response.statusCode, 200)
                XCTAssertTrue(response.isSuccess)
                exp.fulfill()
            }
        wait(for: [exp], timeout: 5)
    }
}
