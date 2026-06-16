import Foundation
import Network
import Security

/// A minimal local HTTP/HTTPS server for the tests that genuinely need a real TLS handshake
/// or URLSession auth challenge (certificate pinning, NSURLCredential auth) — things a
/// `URLProtocol` stub cannot exercise. Serves a fixed JSON body; optionally requires Basic auth.
final class LocalHTTPServer {

    enum ServerError: Error { case identityLoadFailed(OSStatus), noPort }

    private let listener: NWListener
    private let queue = DispatchQueue(label: "com.yaro.alamofireobjc.testserver")

    /// When set, requests without a matching `Authorization: Basic` header get a 401 challenge.
    var basicAuthCredentials: (user: String, password: String)?
    /// Body returned on success.
    var responseBody = Data(#"{"ok":true}"#.utf8)
    /// When set, requests get a 302 redirect to this location.
    var redirectTo: String?
    /// When set, only requests to this exact path are redirected (others are served normally,
    /// so a *followed* redirect to a different path doesn't loop).
    var redirectOnlyPath: String?
    /// When > 0, serve a throttled, range-capable body of this many bytes (for resume tests).
    var rangeBodyTotal: Int = 0
    /// When > 0, wait this long before responding (for timeout / cancel tests).
    var responseDelay: TimeInterval = 0
    /// When true, the 200 response carries `Cache-Control: max-age=60` (for cache-handler test).
    var cacheable = false

    /// The port the server bound to (valid after `start()`).
    private(set) var port: UInt16 = 0

    /// - Parameter tls: when true, serve HTTPS using the bundled self-signed identity.
    init(tls: Bool) throws {
        let parameters: NWParameters
        if tls {
            let identity = try LocalHTTPServer.loadIdentity()
            let tlsOptions = NWProtocolTLS.Options()
            sec_protocol_options_set_local_identity(tlsOptions.securityProtocolOptions, identity)
            parameters = NWParameters(tls: tlsOptions)
        } else {
            parameters = NWParameters.tcp
        }
        parameters.allowLocalEndpointReuse = true
        listener = try NWListener(using: parameters, on: .any)
    }

    /// Start listening and block until a port is assigned.
    func start() throws {
        let ready = DispatchSemaphore(value: 0)
        listener.stateUpdateHandler = { [weak self] state in
            if case .ready = state, let assigned = self?.listener.port?.rawValue {
                self?.port = assigned
                ready.signal()
            }
        }
        listener.newConnectionHandler = { [weak self] connection in
            connection.start(queue: self?.queue ?? .global())
            self?.receive(on: connection, buffer: Data())
        }
        listener.start(queue: queue)
        if ready.wait(timeout: .now() + 5) == .timedOut { throw ServerError.noPort }
    }

    func stop() {
        listener.cancel()
    }

    // MARK: - Request handling

    private func receive(on connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            var accumulated = buffer
            if let data = data { accumulated.append(data) }

            if let headerRange = accumulated.range(of: Data("\r\n\r\n".utf8)) {
                let header = String(decoding: accumulated[..<headerRange.lowerBound], as: UTF8.self)
                let bodyReceived = accumulated[headerRange.upperBound...].count
                let contentLength = self.contentLength(in: header)
                // Drain the whole body before replying so upload progress reaches 1.0.
                if bodyReceived >= contentLength {
                    self.respond(on: connection, requestHeader: header)
                } else if isComplete || error != nil {
                    connection.cancel()
                } else {
                    self.receive(on: connection, buffer: accumulated)
                }
            } else if isComplete || error != nil {
                connection.cancel()
            } else {
                self.receive(on: connection, buffer: accumulated)
            }
        }
    }

    /// The path from the request line, e.g. "GET /start HTTP/1.1" → "/start".
    private func requestPath(in header: String) -> String {
        guard let firstLine = header.split(separator: "\r\n").first else { return "/" }
        let parts = firstLine.split(separator: " ")
        return parts.count >= 2 ? String(parts[1]) : "/"
    }

    private func contentLength(in header: String) -> Int {
        for line in header.split(separator: "\r\n") where line.lowercased().hasPrefix("content-length:") {
            return Int(line.split(separator: ":")[1].trimmingCharacters(in: .whitespaces)) ?? 0
        }
        return 0
    }

    private func respond(on connection: NWConnection, requestHeader: String) {
        if responseDelay > 0 {
            let delay = responseDelay
            responseDelay = 0   // only the first response is delayed
            queue.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.respond(on: connection, requestHeader: requestHeader)
            }
            return
        }
        if let location = redirectTo, redirectOnlyPath == nil || redirectOnlyPath == requestPath(in: requestHeader) {
            send(on: connection, status: "302 Found", extraHeaders: ["Location": location], body: Data())
            return
        }
        if rangeBodyTotal > 0 {
            serveRangeBody(on: connection, requestHeader: requestHeader)
            return
        }
        if let creds = basicAuthCredentials, !isAuthorized(requestHeader, creds: creds) {
            send(on: connection,
                 status: "401 Unauthorized",
                 extraHeaders: ["WWW-Authenticate": "Basic realm=\"test\""],
                 body: Data("auth required".utf8))
        } else {
            var headers = ["Content-Type": "application/json"]
            if cacheable { headers["Cache-Control"] = "max-age=60" }
            send(on: connection, status: "200 OK", extraHeaders: headers, body: responseBody)
        }
    }

    // MARK: - Range / resumable body (throttled so a download can be cancelled mid-flight)

    private func serveRangeBody(on connection: NWConnection, requestHeader: String) {
        let total = rangeBodyTotal
        let start = rangeStart(in: requestHeader)
        let isPartial = start > 0
        let remaining = max(0, total - start)
        var head = "HTTP/1.1 \(isPartial ? "206 Partial Content" : "200 OK")\r\n"
        head += "Content-Length: \(remaining)\r\nAccept-Ranges: bytes\r\nETag: \"fixed-etag\"\r\n"
        head += "Content-Type: application/octet-stream\r\n"
        if isPartial { head += "Content-Range: bytes \(start)-\(total - 1)/\(total)\r\n" }
        head += "Connection: close\r\n\r\n"
        connection.send(content: Data(head.utf8), completion: .contentProcessed { [weak self] _ in
            self?.sendBodyChunk(on: connection, offset: start, total: total)
        })
    }

    private func sendBodyChunk(on connection: NWConnection, offset: Int, total: Int) {
        guard offset < total else {
            connection.send(content: nil, isComplete: true,
                            completion: .contentProcessed { _ in connection.cancel() })
            return
        }
        let chunkSize = 16_384
        let end = min(offset + chunkSize, total)
        let chunk = Data(count: end - offset)
        connection.send(content: chunk, completion: .contentProcessed { [weak self] _ in
            guard let self = self else { return }
            self.queue.asyncAfter(deadline: .now() + 0.005) {
                self.sendBodyChunk(on: connection, offset: end, total: total)
            }
        })
    }

    private func rangeStart(in header: String) -> Int {
        for line in header.split(separator: "\r\n") where line.lowercased().hasPrefix("range:") {
            if let eq = line.firstIndex(of: "="), let dash = line.firstIndex(of: "-") {
                let value = line[line.index(after: eq)..<dash].trimmingCharacters(in: .whitespaces)
                return Int(value) ?? 0
            }
        }
        return 0
    }

    private func isAuthorized(_ header: String, creds: (user: String, password: String)) -> Bool {
        let expected = Data("\(creds.user):\(creds.password)".utf8).base64EncodedString()
        return header.range(of: "Authorization: Basic \(expected)", options: .caseInsensitive) != nil
    }

    private func send(on connection: NWConnection, status: String, extraHeaders: [String: String], body: Data) {
        var head = "HTTP/1.1 \(status)\r\nContent-Length: \(body.count)\r\nConnection: close\r\n"
        for (key, value) in extraHeaders { head += "\(key): \(value)\r\n" }
        head += "\r\n"
        var payload = Data(head.utf8)
        payload.append(body)
        connection.send(content: payload, completion: .contentProcessed { _ in connection.cancel() })
    }

    // MARK: - Identity

    private static func loadIdentity() throws -> sec_identity_t {
        let url = Bundle.module.url(forResource: "server", withExtension: "p12", subdirectory: "Resources")
            ?? Bundle.module.url(forResource: "server", withExtension: "p12")
        let data = try Data(contentsOf: url!)
        var items: CFArray?
        let options = [kSecImportExportPassphrase as String: "test"] as CFDictionary
        let status = SecPKCS12Import(data as CFData, options, &items)
        guard status == errSecSuccess,
              let array = items as? [[String: Any]],
              let identityRaw = array.first?[kSecImportItemIdentity as String] else {
            throw ServerError.identityLoadFailed(status)
        }
        let secIdentity = identityRaw as! SecIdentity
        guard let identity = sec_identity_create(secIdentity) else {
            throw ServerError.identityLoadFailed(errSecParam)
        }
        return identity
    }
}

/// Test helper for loading the DER certificate fixtures.
enum TestCertificates {
    static func der(named name: String) -> Data {
        let url = Bundle.module.url(forResource: name, withExtension: "cer", subdirectory: "Resources")
            ?? Bundle.module.url(forResource: name, withExtension: "cer")!
        return (try? Data(contentsOf: url)) ?? Data()
    }
}
