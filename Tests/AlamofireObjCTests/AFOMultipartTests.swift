import XCTest
@testable import AlamofireObjC

final class AFOMultipartTests: XCTestCase {

    override func tearDown() { StubURLProtocol.reset(); super.tearDown() }

    func testMultipartBodyContainsAllParts() {
        StubURLProtocol.handler = { req in TestSupport.jsonResponse(for: req, body: Data("{}".utf8)) }
        let session = TestSupport.stubbedSession()
        let exp = expectation(description: "multipart")

        let form = AFOMultipartFormData()
        form.appendData(Data("hello".utf8), name: "greeting")
        form.appendData(Data("PNGDATA".utf8), name: "userfile", fileName: "image.png", mimeType: "image/png")

        session.uploadMultipart(form, to: "https://example.com/upload", method: .post, headers: nil)
            .responseJSON { _ in
                let body = StubURLProtocol.lastBody.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                XCTAssertTrue(body.contains("name=\"greeting\""))
                XCTAssertTrue(body.contains("filename=\"image.png\""))
                XCTAssertTrue(body.contains("image/png"))
                XCTAssertTrue(body.contains("PNGDATA"))
                exp.fulfill()
            }
        wait(for: [exp], timeout: 5)
    }

    func testNullStripperRemovesNestedNulls() {
        let input: [String: Any] = ["a": 1, "b": NSNull(), "c": ["d": NSNull(), "e": 2]]
        let result = AFOJSONSerialization.stripNulls(from: input) as? [String: Any]
        XCTAssertNil(result?["b"])
        XCTAssertNil((result?["c"] as? [String: Any])?["d"])
        XCTAssertEqual((result?["c"] as? [String: Any])?["e"] as? Int, 2)
    }
}
