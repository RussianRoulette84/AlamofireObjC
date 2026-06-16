import Foundation
import Alamofire

/// Retry decision returned by an interceptor's retrier block.
@objc(AFORetryResult)
public enum AFORetryResult: Int {
    case doNotRetry
    case retry
    case retryWithDelay
}

/// A retrier's verdict: whether to retry and, if delayed, after how long.
@objc(AFORetryDecision)
public final class AFORetryDecision: NSObject {
    @objc public let result: AFORetryResult
    @objc public let delay: TimeInterval

    @objc public init(result: AFORetryResult, delay: TimeInterval) {
        self.result = result
        self.delay = delay
        super.init()
    }

    @objc public static func doNotRetry() -> AFORetryDecision { AFORetryDecision(result: .doNotRetry, delay: 0) }
    @objc public static func retry() -> AFORetryDecision { AFORetryDecision(result: .retry, delay: 0) }
    @objc public static func retry(afterDelay delay: TimeInterval) -> AFORetryDecision {
        AFORetryDecision(result: .retryWithDelay, delay: delay)
    }
}

/// Block-driven bridge for Alamofire's `RequestInterceptor` (adapter + retrier).
///
/// The adapter block can mutate every outgoing request (e.g. stamp an `X-Token` header).
/// The retrier block decides whether a failed request should be retried.
@objc(AFOInterceptor)
public final class AFOInterceptor: NSObject, RequestInterceptor, @unchecked Sendable {

    // Mutable blocks are read on Alamofire's internal queues and written by callers, so they
    // are guarded by a lock — which is what makes `@unchecked Sendable` correct here.
    private let lock = NSLock()
    private var _adapterBlock: ((URLRequest) -> URLRequest)?
    private var _retrierBlock: ((NSError, Int) -> AFORetryDecision)?

    /// Modify each outgoing request. Return the (possibly mutated) request.
    @objc public var adapterBlock: ((URLRequest) -> URLRequest)? {
        get { lock.lock(); defer { lock.unlock() }; return _adapterBlock }
        set { lock.lock(); _adapterBlock = newValue; lock.unlock() }
    }

    /// Decide whether to retry a failed request.
    @objc public var retrierBlock: ((NSError, Int) -> AFORetryDecision)? {
        get { lock.lock(); defer { lock.unlock() }; return _retrierBlock }
        set { lock.lock(); _retrierBlock = newValue; lock.unlock() }
    }

    @objc public override init() {
        super.init()
    }

    /// Convenience: an interceptor that injects a single header on every request.
    @objc public static func headerInjector(_ field: String, value: String) -> AFOInterceptor {
        let interceptor = AFOInterceptor()
        interceptor.adapterBlock = { request in
            var mutable = request
            mutable.setValue(value, forHTTPHeaderField: field)
            return mutable
        }
        return interceptor
    }

    /// Internal handle used when building a `Session`.
    var interceptor: RequestInterceptor { self }

    // MARK: - RequestInterceptor

    public func adapt(_ urlRequest: URLRequest,
                      for session: Session,
                      completion: @escaping (Result<URLRequest, Error>) -> Void) {
        if let adapterBlock = adapterBlock {
            completion(.success(adapterBlock(urlRequest)))
        } else {
            completion(.success(urlRequest))
        }
    }

    public func retry(_ request: Request,
                      for session: Session,
                      dueTo error: Error,
                      completion: @escaping (RetryResult) -> Void) {
        guard let retrierBlock = retrierBlock else { completion(.doNotRetry); return }
        let decision = retrierBlock(AFOError.error(from: error), request.retryCount)
        switch decision.result {
        case .doNotRetry: completion(.doNotRetry)
        case .retry: completion(.retry)
        case .retryWithDelay: completion(.retryWithDelay(decision.delay))
        }
    }
}
