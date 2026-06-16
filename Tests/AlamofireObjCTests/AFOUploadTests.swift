import XCTest
@testable import AlamofireObjC

final class AFOUploadTests: XCTestCase {

    override func tearDown() { StubURLProtocol.reset(); super.tearDown() }

    private func okStub() {
        StubURLProtocol.handler = { req in
            let response = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: "HTTP/1.1",
                                           headerFields: ["Content-Type": "application/json"])!
            return (response, Data("{}".utf8))
        }
    }

    func testUploadDataSendsBody() {
        okStub()
        let session = TestSupport.stubbedSession()
        let exp = expectation(description: "data")
        let payload = Data("raw-upload".utf8)

        session.uploadData(payload, to: "https://example.com/u", method: .post, headers: nil)
            .responseJSON { _ in
                XCTAssertEqual(StubURLProtocol.lastBody, payload)
                exp.fulfill()
            }
        wait(for: [exp], timeout: 5)
    }

    func testUploadFileSendsContents() throws {
        okStub()
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("afo-up-\(UUID().uuidString).txt")
        let contents = Data("file-contents".utf8)
        try contents.write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let session = TestSupport.stubbedSession()
        let exp = expectation(description: "file")
        session.uploadFile(fileURL, to: "https://example.com/u", method: .post, headers: nil)
            .responseJSON { _ in
                XCTAssertEqual(StubURLProtocol.lastBody, contents)
                exp.fulfill()
            }
        wait(for: [exp], timeout: 5)
    }

    func testUploadStreamSendsContents() {
        okStub()
        let bytes = Data("stream-bytes".utf8)
        let session = TestSupport.stubbedSession()
        let exp = expectation(description: "stream")
        session.uploadStream(InputStream(data: bytes), to: "https://example.com/u", method: .post, headers: nil)
            .responseJSON { _ in
                XCTAssertEqual(StubURLProtocol.lastBody, bytes)
                exp.fulfill()
            }
        wait(for: [exp], timeout: 5)
    }

    /// Upload progress against a real TLS server (URLProtocol stubs don't report send progress).
    func testUploadProgressReachesOne() throws {
        let server = try LocalHTTPServer(tls: true)
        try server.start()
        defer { server.stop() }

        let trust = AFOServerTrustManager(policies: ["localhost": .disabled()], allHostsMustBeEvaluated: true)
        let session = AFOSession(configuration: .ephemeral, serverTrustManager: trust,
                                 interceptor: nil, redirectHandler: nil,
                                 cachedResponseHandler: nil, eventMonitor: nil)
        let payload = Data(repeating: 0x41, count: 256 * 1024)
        let exp = expectation(description: "upload progress")
        var lastFraction: Double = 0

        session.uploadData(payload, to: "https://localhost:\(server.port)/", method: .post, headers: nil)
            .uploadProgress { progress in lastFraction = progress.fractionCompleted }
            .responseData { _ in
                XCTAssertEqual(lastFraction, 1.0, accuracy: 0.001)
                exp.fulfill()
            }
        wait(for: [exp], timeout: 15)
    }
}
