import Foundation
import Alamofire

/// AFNetworking `AFHTTPSessionManager` look-alike, for near drop-in migration. Wraps the
/// chainable core (`AFOSession`/`AFORequest`) so there is one engine underneath.
///
/// Configure `requestEncoding` (JSON vs URL), `removesKeysWithNullValues`, `defaultHeaders`
/// (e.g. an `X-Token`), `securityPolicy` and `logsCURLRequests`, then call the verb methods.
@objc(AFOHTTPSessionManager)
public final class AFOHTTPSessionManager: NSObject {

    public typealias Success = (URLSessionTask?, Any?) -> Void
    public typealias Failure = (URLSessionTask?, NSError) -> Void

    @objc public let baseURL: URL?

    /// JSON (default) or URL-encoded request bodies.
    @objc public var requestEncoding: AFOParameterEncoding = .JSON
    /// Strip NSNull from parsed JSON responses (AFNetworking parity). Default YES.
    @objc public var removesKeysWithNullValues: Bool = true
    /// Headers stamped on every request (merged under per-call headers).
    @objc public var defaultHeaders: [String: String] = [:]
    /// Optional pinning configuration.
    @objc public var securityPolicy: AFOSecurityPolicy? { didSet { invalidateSession() } }
    /// When YES, every request's cURL command is delivered to `curlLogger` (or NSLog'd).
    @objc public var logsCURLRequests: Bool = false { didSet { invalidateSession() } }
    /// Receives cURL strings when `logsCURLRequests` is YES. Defaults to NSLog.
    @objc public var curlLogger: ((String) -> Void)? { didSet { invalidateSession() } }
    /// Optional response validation applied to every request.
    @objc public var validation: AFOValidationConfig?
    /// Optional URLSession configuration (timeouts, custom protocol classes, etc.).
    /// Defaults to `URLSessionConfiguration.default` when nil.
    @objc public var sessionConfiguration: URLSessionConfiguration? { didSet { invalidateSession() } }

    private var _session: AFOSession?

    /// Drop the cached session so the next request rebuilds with current trust/monitor/config.
    /// (`requestEncoding`/`defaultHeaders`/`validation`/`removesKeysWithNullValues` are applied
    /// per-request, so they take effect immediately without a rebuild.)
    private func invalidateSession() { _session = nil }

    @objc public init(baseURL: URL?) {
        self.baseURL = baseURL
        super.init()
    }

    @objc public static func manager(baseURL: URL?) -> AFOHTTPSessionManager {
        AFOHTTPSessionManager(baseURL: baseURL)
    }

    // MARK: - Verb methods

    @discardableResult
    @objc public func get(_ URLString: String, parameters: [String: Any]?, headers: [String: String]?,
                          progress: ((Progress) -> Void)?, success: Success?, failure: Failure?) -> AFORequest {
        perform(.get, URLString, parameters, headers, progress, success, failure)
    }

    @discardableResult
    @objc public func post(_ URLString: String, parameters: [String: Any]?, headers: [String: String]?,
                           progress: ((Progress) -> Void)?, success: Success?, failure: Failure?) -> AFORequest {
        perform(.post, URLString, parameters, headers, progress, success, failure)
    }

    @discardableResult
    @objc public func put(_ URLString: String, parameters: [String: Any]?, headers: [String: String]?,
                          success: Success?, failure: Failure?) -> AFORequest {
        perform(.put, URLString, parameters, headers, nil, success, failure)
    }

    @discardableResult
    @objc public func patch(_ URLString: String, parameters: [String: Any]?, headers: [String: String]?,
                            success: Success?, failure: Failure?) -> AFORequest {
        perform(.patch, URLString, parameters, headers, nil, success, failure)
    }

    @discardableResult
    @objc public func delete(_ URLString: String, parameters: [String: Any]?, headers: [String: String]?,
                             success: Success?, failure: Failure?) -> AFORequest {
        perform(.delete, URLString, parameters, headers, nil, success, failure)
    }

    @discardableResult
    @objc public func head(_ URLString: String, parameters: [String: Any]?, headers: [String: String]?,
                           success: Success?, failure: Failure?) -> AFORequest {
        perform(.head, URLString, parameters, headers, nil, success, failure)
    }

    // MARK: - Engine

    func session() -> AFOSession {
        if let session = _session { return session }
        var trustManager: AFOServerTrustManager?
        if let host = baseURL?.host { trustManager = securityPolicy?.trustManager(forHost: host) }

        var monitor: AFOEventMonitor?
        if logsCURLRequests {
            let eventMonitor = AFOEventMonitor()
            eventMonitor.didResolveCURL = { [weak self] curl in
                if let logger = self?.curlLogger { logger(curl) } else { NSLog("%@", curl) }
            }
            monitor = eventMonitor
        }
        let session = AFOSession(configuration: sessionConfiguration ?? .default,
                                 serverTrustManager: trustManager,
                                 interceptor: nil,
                                 redirectHandler: nil,
                                 cachedResponseHandler: nil,
                                 eventMonitor: monitor)
        _session = session
        return session
    }

    /// Resolve a possibly-relative path against `baseURL`.
    func resolvedURL(_ URLString: String) -> String {
        if let baseURL = baseURL, URL(string: URLString)?.scheme == nil {
            return URL(string: URLString, relativeTo: baseURL)?.absoluteString ?? URLString
        }
        return URLString
    }

    private func perform(_ method: AFOHTTPMethod, _ URLString: String, _ parameters: [String: Any]?,
                         _ headers: [String: String]?, _ progress: ((Progress) -> Void)?,
                         _ success: Success?, _ failure: Failure?) -> AFORequest {
        var merged = defaultHeaders
        headers?.forEach { merged[$0.key] = $0.value }

        let request = session().request(resolvedURL(URLString), method: method, parameters: parameters,
                                        encoding: requestEncoding, headers: merged)
        request.removesKeysWithNullValues = removesKeysWithNullValues
        if let validation = validation { request.validateWithConfig(validation) }
        if let progress = progress { request.uploadProgress(progress) }

        request.responseJSON { response in
            let task = request.task
            if let error = response.error { failure?(task, error) } else { success?(task, response.value) }
        }
        return request
    }
}
