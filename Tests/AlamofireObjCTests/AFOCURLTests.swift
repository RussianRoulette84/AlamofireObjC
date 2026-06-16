import XCTest
@testable import AlamofireObjC

final class AFOCURLTests: XCTestCase {

    override func tearDown() { StubURLProtocol.reset(); super.tearDown() }

    func testCURLDescriptionContainsMethodURLHeaderAndBody() {
        StubURLProtocol.handler = { req in TestSupport.jsonResponse(for: req, body: Data("{}".utf8)) }
        let session = TestSupport.stubbedSession()
        let exp = expectation(description: "curl")

        session.request("https://example.com/things", method: .post,
                        parameters: ["title": "Pin"], encoding: .JSON,
                        headers: ["X-Token": "abc"])
            .cURLDescription { curl in
                XCTAssertTrue(curl.contains("curl"))
                XCTAssertTrue(curl.contains("-X POST"))
                XCTAssertTrue(curl.contains("https://example.com/things"))
                XCTAssertTrue(curl.contains("X-Token: abc"))
                XCTAssertTrue(curl.contains("Pin"))
                exp.fulfill()
            }
            .responseData { _ in }   // force the request to run so the URLRequest is created

        wait(for: [exp], timeout: 5)
    }
}
