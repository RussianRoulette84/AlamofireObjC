import XCTest
@testable import AlamofireObjC

final class AFOPlistAndVerbTests: XCTestCase {

    override func tearDown() { StubURLProtocol.reset(); super.tearDown() }

    private func okStub() {
        StubURLProtocol.handler = { req in TestSupport.jsonResponse(for: req, body: Data("{}".utf8)) }
    }

    func testPlistXMLEncodingSetsContentTypeAndBody() {
        okStub()
        let session = TestSupport.stubbedSession()
        let exp = expectation(description: "plist")

        session.request("https://example.com/x", method: .post,
                        parameters: ["name": "Yaro", "count": 3],
                        encoding: .propertyListXML, headers: nil)
            .responseJSON { _ in
                XCTAssertEqual(StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "Content-Type"),
                               "application/x-plist")
                let body = StubURLProtocol.lastBody ?? Data()
                let plist = try? PropertyListSerialization.propertyList(from: body, options: [], format: nil)
                XCTAssertEqual((plist as? [String: Any])?["name"] as? String, "Yaro")
                exp.fulfill()
            }
        wait(for: [exp], timeout: 5)
    }

    func testPlistAcceptsArrayValues() {
        okStub()
        let session = TestSupport.stubbedSession()
        let exp = expectation(description: "plist-array")

        session.request("https://example.com/x", method: .post,
                        parameters: ["tags": ["a", "b"], "name": "Yaro"],
                        encoding: .propertyListXML, headers: nil)
            .responseJSON { _ in
                let body = StubURLProtocol.lastBody ?? Data()
                let plist = try? PropertyListSerialization.propertyList(from: body, options: [], format: nil)
                XCTAssertEqual((plist as? [String: Any])?["tags"] as? [String], ["a", "b"])
                exp.fulfill()
            }
        wait(for: [exp], timeout: 5)
    }

    func testAllVerbsSetCorrectMethod() {
        okStub()
        let session = TestSupport.stubbedSession()
        let verbs: [(AFOHTTPMethod, String)] = [(.put, "PUT"), (.delete, "DELETE"),
                                                (.patch, "PATCH"), (.head, "HEAD")]
        for (method, name) in verbs {
            let exp = expectation(description: name)
            session.request("https://example.com/\(name)", method: method, parameters: nil,
                            encoding: .URLDefault, headers: nil)
                .responseData { _ in
                    XCTAssertEqual(StubURLProtocol.lastRequest?.httpMethod, name)
                    exp.fulfill()
                }
            wait(for: [exp], timeout: 5)
        }
    }
}
