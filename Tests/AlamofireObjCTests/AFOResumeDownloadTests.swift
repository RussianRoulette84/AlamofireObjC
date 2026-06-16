import XCTest
@testable import AlamofireObjC

/// #8 — functional resume-data download: start → cancel(producingResumeData) mid-flight →
/// resume → completes. Uses a plain-HTTP, range-capable, throttled server.
final class AFOResumeDownloadTests: XCTestCase {

    private var server: LocalHTTPServer!
    private let total = 2_000_000

    override func setUpWithError() throws {
        server = try LocalHTTPServer(tls: false)
        server.rangeBodyTotal = total
        try server.start()
    }

    override func tearDown() {
        server.stop()
        server = nil
        super.tearDown()
    }

    func testResumeCompletesDownload() {
        let session = AFOSession(configuration: .ephemeral, serverTrustManager: nil,
                                 interceptor: nil, redirectHandler: nil,
                                 cachedResponseHandler: nil, eventMonitor: nil)
        let url = "http://localhost:\(server.port)/large"
        let finalURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("afo-resume-\(UUID().uuidString).bin")

        let cancelled = expectation(description: "cancelled")
        let resumed = expectation(description: "resumed")
        var resumeData: Data?
        var didCancel = false

        let first = session.download(url, method: .get, parameters: nil, encoding: .URLDefault,
                                     headers: nil, destination: { _, _ in finalURL })
        first.downloadProgress { [weak first] progress in
            guard progress.fractionCompleted > 0.1, !didCancel else { return }
            didCancel = true
            first?.cancelProducingResumeData(true) { data in
                resumeData = data
                XCTAssertNotNil(data, "cancel should yield resume data")
                cancelled.fulfill()
            }
        }
        first.responseURL { _, _, _ in }   // first download ends cancelled
        wait(for: [cancelled], timeout: 20)

        guard let resumeData = resumeData else { return XCTFail("no resume data") }
        session.downloadResuming(with: resumeData, destination: { _, _ in finalURL })
            .responseURL { fileURL, _, error in
                XCTAssertNil(error)
                XCTAssertNotNil(fileURL)
                let size = (try? Data(contentsOf: finalURL))?.count ?? 0
                XCTAssertEqual(size, self.total, "resumed file should be the full size")
                resumed.fulfill()
            }
        wait(for: [resumed], timeout: 20)
        try? FileManager.default.removeItem(at: finalURL)
    }
}
