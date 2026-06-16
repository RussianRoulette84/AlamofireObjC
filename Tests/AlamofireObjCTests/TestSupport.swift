import Foundation
@testable import AlamofireObjC

/// Shared helpers for the test suite.
enum TestSupport {

    /// A session whose traffic is intercepted by `StubURLProtocol`.
    static func stubbedSession() -> AFOSession {
        AFOSession(configuration: StubURLProtocol.configuration(),
                   serverTrustManager: nil,
                   interceptor: nil,
                   redirectHandler: nil,
                   cachedResponseHandler: nil,
                   eventMonitor: nil)
    }

    /// Build a 200 JSON response for a request.
    static func jsonResponse(for request: URLRequest, body: Data, status: Int = 200) -> (HTTPURLResponse, Data?) {
        let response = HTTPURLResponse(url: request.url!, statusCode: status,
                                       httpVersion: "HTTP/1.1",
                                       headerFields: ["Content-Type": "application/json"])!
        return (response, body)
    }
}
