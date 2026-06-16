import Foundation

/// Objective-C ergonomics for NSErrors produced by AlamofireObjC. These accessors only carry
/// meaning for errors in `AlamofireObjCErrorDomain`; others report `.unknown` / 0 / nil.
@objc public extension NSError {

    /// The failure category, or `.unknown` for errors from other domains.
    var afoErrorCode: AFOErrorCode {
        guard domain == AFOError.errorDomain else { return .unknown }
        return AFOErrorCode(rawValue: code) ?? .unknown
    }

    /// HTTP status code captured at failure time, or 0 if none.
    var afoStatusCode: Int {
        (userInfo[AFOError.statusCodeKey] as? Int) ?? 0
    }

    /// The underlying transport error, if any.
    var afoUnderlyingError: NSError? {
        userInfo[AFOError.underlyingKey] as? NSError
    }

    /// The failing URL, if captured.
    var afoFailingURL: URL? {
        userInfo[AFOError.failingURLKey] as? URL
    }

    /// True when the request was explicitly cancelled.
    var afoIsCancelled: Bool {
        afoErrorCode == .explicitlyCancelled
    }
}
