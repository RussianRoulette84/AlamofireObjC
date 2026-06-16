import Foundation
import Alamofire

/// Error domain for all bridged failures.
public let AlamofireObjCErrorDomain = "AlamofireObjCErrorDomain"

/// Translates Alamofire's `AFError` (and any other `Error`) into an Objective-C `NSError`.
@objc(AFOError)
public final class AFOError: NSObject {

    /// Error domain, ObjC-visible.
    @objc public static let errorDomain = AlamofireObjCErrorDomain
    /// Keys placed into the produced NSError's userInfo (ObjC-visible).
    @objc public static let statusCodeKey = "AFOErrorStatusCodeKey"
    @objc public static let underlyingKey = "AFOErrorUnderlyingKey"
    @objc public static let failingURLKey = "AFOErrorFailingURLKey"

    /// Convert any Swift error into an ObjC-friendly NSError, preserving HTTP status,
    /// the underlying transport error and the failing URL where available.
    @objc public static func error(from error: Error) -> NSError {
        if let afError = error.asAFError {
            return make(from: afError)
        }
        return error as NSError
    }

    private static func make(from afError: AFError) -> NSError {
        var info: [String: Any] = [
            NSLocalizedDescriptionKey: afError.localizedDescription
        ]

        if let status = afError.responseCode {
            info[Self.statusCodeKey] = status
        }
        if let underlying = afError.underlyingError {
            info[Self.underlyingKey] = underlying as NSError
        }
        if let url = afError.url {
            info[Self.failingURLKey] = url
        }

        return NSError(domain: AlamofireObjCErrorDomain,
                       code: code(for: afError).rawValue,
                       userInfo: info)
    }

    /// Categorize an AFError so ObjC callers can branch via `NSError.afoErrorCode`.
    private static func code(for afError: AFError) -> AFOErrorCode {
        switch afError {
        case .invalidURL: return .invalidURL
        case .parameterEncodingFailed: return .parameterEncodingFailed
        case .parameterEncoderFailed: return .parameterEncoderFailed
        case .multipartEncodingFailed: return .multipartEncodingFailed
        case .requestAdaptationFailed: return .requestAdaptationFailed
        case .responseValidationFailed: return .responseValidationFailed
        case .responseSerializationFailed: return .responseSerializationFailed
        case .serverTrustEvaluationFailed: return .serverTrustEvaluationFailed
        case .requestRetryFailed: return .requestRetryFailed
        case .sessionDeinitialized: return .sessionDeinitialized
        case .sessionInvalidated: return .sessionInvalidated
        case .sessionTaskFailed: return .sessionTaskFailed
        case .explicitlyCancelled: return .explicitlyCancelled
        case .createUploadableFailed: return .createUploadableFailed
        case .createURLRequestFailed: return .createURLRequestFailed
        case .downloadedFileMoveFailed: return .downloadedFileMoveFailed
        case .urlRequestValidationFailed: return .urlRequestValidationFailed
        @unknown default: return .unknown
        }
    }
}
