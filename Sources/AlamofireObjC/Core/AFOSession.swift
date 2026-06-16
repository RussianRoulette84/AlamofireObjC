import Foundation
import Alamofire

/// The Objective-C entry point — wraps an Alamofire `Session` and vends `AFORequest`,
/// `AFOUploadRequest`, `AFODownloadRequest` and `AFODataStreamRequest` objects.
@objc(AFOSession)
public final class AFOSession: NSObject {

    let session: Session

    /// Shared session wrapping `Session.default`.
    @objc public static let shared = AFOSession(session: .default)

    init(session: Session) {
        self.session = session
        super.init()
    }

    /// Default session with the standard configuration.
    @objc public override convenience init() {
        self.init(session: Session())
    }

    /// Fully configured session.
    @objc public convenience init(configuration: URLSessionConfiguration,
                                  serverTrustManager: AFOServerTrustManager?,
                                  interceptor: AFOInterceptor?,
                                  redirectHandler: AFORedirectHandler?,
                                  cachedResponseHandler: AFOCachedResponseHandler?,
                                  eventMonitor: AFOEventMonitor?) {
        let monitors: [EventMonitor] = eventMonitor.map { [$0] } ?? []
        let session = Session(configuration: configuration,
                              interceptor: interceptor?.interceptor,
                              serverTrustManager: serverTrustManager?.manager,
                              redirectHandler: redirectHandler?.handler,
                              cachedResponseHandler: cachedResponseHandler?.handler,
                              eventMonitors: monitors)
        self.init(session: session)
    }

    /// Configured session with an exponential-backoff retry policy. An optional `interceptor`
    /// (adapter/retrier) is composed with the retry policy.
    @objc public convenience init(configuration: URLSessionConfiguration,
                                  serverTrustManager: AFOServerTrustManager?,
                                  interceptor: AFOInterceptor?,
                                  retryPolicy: AFORetryPolicy?,
                                  redirectHandler: AFORedirectHandler?,
                                  cachedResponseHandler: AFOCachedResponseHandler?,
                                  eventMonitor: AFOEventMonitor?) {
        let monitors: [EventMonitor] = eventMonitor.map { [$0] } ?? []
        let pieces: [RequestInterceptor] = [interceptor?.interceptor, retryPolicy?.interceptor].compactMap { $0 }
        let combined: RequestInterceptor? = pieces.isEmpty ? nil : Interceptor(interceptors: pieces)
        let session = Session(configuration: configuration,
                              interceptor: combined,
                              serverTrustManager: serverTrustManager?.manager,
                              redirectHandler: redirectHandler?.handler,
                              cachedResponseHandler: cachedResponseHandler?.handler,
                              eventMonitors: monitors)
        self.init(session: session)
    }

    /// Cancel every in-flight request on this session (data, upload, download).
    @objc public func cancelAllRequests() {
        session.cancelAllRequests()
    }

    // MARK: - Data requests

    /// Issue a data request. `parameters` may be nil; `encoding` selects URL/JSON/plist.
    @discardableResult
    @objc public func request(_ url: String,
                              method: AFOHTTPMethod,
                              parameters: [String: Any]?,
                              encoding: AFOParameterEncoding,
                              headers: [String: String]?) -> AFORequest {
        let request = session.request(url,
                                      method: method.alamofire,
                                      parameters: parameters,
                                      encoding: encoding.makeEncoding(),
                                      headers: AFOHeaders.make(from: headers))
        return AFORequest(request: request)
    }

    /// Convenience GET with no parameters.
    @discardableResult
    @objc public func get(_ url: String, headers: [String: String]?) -> AFORequest {
        request(url, method: .get, parameters: nil, encoding: .URLDefault, headers: headers)
    }

    /// Data request with per-request overrides: a `timeout` (seconds; <= 0 means default) and
    /// an optional per-request `interceptor` (adapter/retrier just for this call).
    @discardableResult
    @objc public func request(_ url: String,
                              method: AFOHTTPMethod,
                              parameters: [String: Any]?,
                              encoding: AFOParameterEncoding,
                              headers: [String: String]?,
                              timeout: TimeInterval,
                              interceptor: AFOInterceptor?) -> AFORequest {
        let request = session.request(url,
                                      method: method.alamofire,
                                      parameters: parameters,
                                      encoding: encoding.makeEncoding(),
                                      headers: AFOHeaders.make(from: headers),
                                      interceptor: interceptor?.interceptor,
                                      requestModifier: { urlRequest in
                                          if timeout > 0 { urlRequest.timeoutInterval = timeout }
                                      })
        return AFORequest(request: request)
    }

    // MARK: - Data stream

    /// Issue a streaming request. Observe chunks via `AFODataStreamRequest.onStream:`.
    @discardableResult
    @objc public func streamRequest(_ url: String,
                                    method: AFOHTTPMethod,
                                    headers: [String: String]?) -> AFODataStreamRequest {
        let request = session.streamRequest(url,
                                            method: method.alamofire,
                                            headers: AFOHeaders.make(from: headers))
        return AFODataStreamRequest(request: request)
    }
}
