import Foundation

/// Lightweight in-process HTTP stub. Register a handler and point an `AFOSession` at a
/// `URLSessionConfiguration` whose `protocolClasses` contains this class. Avoids a real
/// socket server for the HTTP-behaviour tests.
final class StubURLProtocol: URLProtocol {

    /// Produces (response, body) for a request, or throws to simulate a transport error.
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    /// Captures the most recent request body for assertions (URLProtocol strips httpBody for
    /// streamed bodies, so this also drains httpBodyStream).
    static var lastRequest: URLRequest?
    static var lastBody: Data?

    static func reset() {
        handler = nil
        lastRequest = nil
        lastBody = nil
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        StubURLProtocol.lastRequest = request
        StubURLProtocol.lastBody = StubURLProtocol.body(from: request)

        guard let handler = StubURLProtocol.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data = data { client?.urlProtocol(self, didLoad: data) }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    private static func body(from request: URLRequest) -> Data? {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let size = 4096
        var buffer = [UInt8](repeating: 0, count: size)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: size)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        return data
    }

    /// Build a config wired to this stub.
    static func configuration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return config
    }
}
