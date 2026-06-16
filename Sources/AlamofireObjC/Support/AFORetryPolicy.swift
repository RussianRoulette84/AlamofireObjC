import Foundation
import Alamofire

/// Bridges Alamofire's built-in exponential-backoff `RetryPolicy` — retries idempotent
/// requests that fail with retryable status/URL-error codes, backing off between attempts.
/// Pass to `AFOSession`'s retry-aware initializer.
@objc(AFORetryPolicy)
public final class AFORetryPolicy: NSObject, @unchecked Sendable {

    let policy: RetryPolicy

    /// - Parameters:
    ///   - retryLimit: max retries per request.
    ///   - exponentialBackoffBase: backoff base (delay = base^retryCount * scale).
    ///   - exponentialBackoffScale: backoff scale in seconds.
    @objc public init(retryLimit: UInt,
                      exponentialBackoffBase: UInt,
                      exponentialBackoffScale: Double) {
        // Alamofire's RetryPolicy hard-requires base >= 2 (it `precondition`s otherwise, which
        // would crash the app). Clamp so an ObjC caller can never trip it.
        policy = RetryPolicy(retryLimit: retryLimit,
                             exponentialBackoffBase: max(2, exponentialBackoffBase),
                             exponentialBackoffScale: exponentialBackoffScale)
        super.init()
    }

    /// Default policy (2 retries, base 2, scale 0.5s).
    @objc public override convenience init() {
        self.init(retryLimit: 2, exponentialBackoffBase: 2, exponentialBackoffScale: 0.5)
    }

    var interceptor: RequestInterceptor { policy }
}
