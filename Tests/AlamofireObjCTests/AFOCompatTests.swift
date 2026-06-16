import XCTest
@testable import AlamofireObjC

final class AFOCompatTests: XCTestCase {

    override func tearDown() { StubURLProtocol.reset(); super.tearDown() }

    private func manager() -> AFOHTTPSessionManager {
        let manager = AFOHTTPSessionManager(baseURL: URL(string: "https://example.com"))
        manager.sessionConfiguration = StubURLProtocol.configuration()
        return manager
    }

    func testGetResolvesRelativePathAndSucceeds() {
        StubURLProtocol.handler = { req in TestSupport.jsonResponse(for: req, body: #"{"ok":true}"#.data(using: .utf8)!) }
        let exp = expectation(description: "get")

        let mgr = manager()
        mgr.get("/users", parameters: nil, headers: nil, progress: nil,
                      success: { _, obj in
                          XCTAssertEqual((obj as? [String: Any])?["ok"] as? Bool, true)
                          XCTAssertEqual(StubURLProtocol.lastRequest?.url?.path, "/users")
                          exp.fulfill()
                      }, failure: { _, error in XCTFail("\(error)"); exp.fulfill() })
        wait(for: [exp], timeout: 5)
    }

    func testTogglingConfigAfterFirstRequestRebuildsSession() {
        StubURLProtocol.handler = { req in TestSupport.jsonResponse(for: req, body: Data("{}".utf8)) }
        let mgr = manager()

        let first = expectation(description: "first")
        mgr.get("/a", parameters: nil, headers: nil, progress: nil,
                success: { _, _ in first.fulfill() },
                failure: { _, err in XCTFail("\(err)"); first.fulfill() })
        wait(for: [first], timeout: 5)

        // Enable cURL logging AFTER the first request. If the cached session weren't
        // invalidated, the logger would never fire (the #3 footgun).
        let logged = expectation(description: "logged")
        logged.assertForOverFulfill = false
        mgr.curlLogger = { _ in logged.fulfill() }
        mgr.logsCURLRequests = true
        mgr.get("/b", parameters: nil, headers: nil, progress: nil,
                success: { _, _ in }, failure: { _, _ in })
        wait(for: [logged], timeout: 5)
    }

    func testMultipartFoldsScalarsSkipsComplexValues() {
        StubURLProtocol.handler = { req in TestSupport.jsonResponse(for: req, body: Data("{}".utf8)) }
        let mgr = manager()
        let exp = expectation(description: "multipart")

        mgr.post("/upload", parameters: ["count": 3, "obj": ["k": "v"]], headers: nil,
                 constructingBody: { form in
                     form.appendData(Data("img".utf8), name: "file", fileName: "i.jpg", mimeType: "image/jpeg")
                 }, progress: nil,
                 success: { _, _ in
                     let body = String(data: StubURLProtocol.lastBody ?? Data(), encoding: .utf8) ?? ""
                     XCTAssertTrue(body.contains("name=\"count\""), "scalar folded")
                     XCTAssertTrue(body.contains("\r\n3"), "NSNumber rendered as 3")
                     XCTAssertFalse(body.contains("name=\"obj\""), "complex value skipped, not stringified")
                     exp.fulfill()
                 }, failure: { _, error in XCTFail("\(error)"); exp.fulfill() })
        wait(for: [exp], timeout: 5)
    }

    func testDefaultHeadersAndNullStripping() {
        StubURLProtocol.handler = { req in TestSupport.jsonResponse(for: req, body: #"{"a":1,"b":null}"#.data(using: .utf8)!) }
        let mgr = manager()
        mgr.defaultHeaders = ["X-Token": "abc"]
        let exp = expectation(description: "post")

        mgr.post("/thing", parameters: ["x": 1], headers: nil, progress: nil,
                 success: { _, obj in
                     XCTAssertEqual(StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "X-Token"), "abc")
                     let dict = obj as? [String: Any]
                     XCTAssertNotNil(dict?["a"])
                     XCTAssertNil(dict?["b"], "null stripped by default")
                     exp.fulfill()
                 }, failure: { _, error in XCTFail("\(error)"); exp.fulfill() })
        wait(for: [exp], timeout: 5)
    }
}
