import XCTest
@testable import AlamofireObjC

final class AFODownloadTests: XCTestCase {

    override func tearDown() { StubURLProtocol.reset(); super.tearDown() }

    func testDownloadWritesToDestination() {
        let payload = Data("downloaded-bytes".utf8)
        StubURLProtocol.handler = { req in
            let response = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: "HTTP/1.1",
                                           headerFields: ["Content-Type": "application/octet-stream"])!
            return (response, payload)
        }
        let session = TestSupport.stubbedSession()
        let destURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("afo-\(UUID().uuidString).bin")
        let exp = expectation(description: "download")

        session.download("https://example.com/file.bin", method: .get, parameters: nil,
                         encoding: .URLDefault, headers: nil,
                         destination: { _, _ in destURL })
            .responseURL { fileURL, _, error in
                XCTAssertNil(error)
                XCTAssertNotNil(fileURL)
                XCTAssertEqual(try? Data(contentsOf: destURL), payload)
                exp.fulfill()
            }
        wait(for: [exp], timeout: 5)
        try? FileManager.default.removeItem(at: destURL)
    }

    func testDownloadReportsProgressComplete() {
        StubURLProtocol.handler = { req in
            let response = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: "HTTP/1.1",
                                           headerFields: ["Content-Length": "4"])!
            return (response, Data("data".utf8))
        }
        let session = TestSupport.stubbedSession()
        let exp = expectation(description: "progress")
        var lastFraction: Double = 0

        session.download("https://example.com/x", method: .get, parameters: nil,
                         encoding: .URLDefault, headers: nil, destination: nil)
            .downloadProgress { progress in lastFraction = progress.fractionCompleted }
            .responseData { _, _, _ in
                XCTAssertEqual(lastFraction, 1.0, accuracy: 0.001)
                exp.fulfill()
            }
        wait(for: [exp], timeout: 5)
    }
}
