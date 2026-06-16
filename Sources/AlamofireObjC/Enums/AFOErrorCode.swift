import Foundation

/// Objective-C-visible error codes for `NSError`s in `AlamofireObjCErrorDomain`. Lets callers
/// branch on the failure category instead of magic integers.
@objc(AFOErrorCode)
public enum AFOErrorCode: Int {
    case unknown = -1
    case invalidURL = 1
    case parameterEncodingFailed = 2
    case parameterEncoderFailed = 3
    case multipartEncodingFailed = 4
    case requestAdaptationFailed = 5
    case responseValidationFailed = 6
    case responseSerializationFailed = 7
    case serverTrustEvaluationFailed = 8
    case requestRetryFailed = 9
    case sessionDeinitialized = 10
    case sessionInvalidated = 11
    case sessionTaskFailed = 12
    case explicitlyCancelled = 13
    case createUploadableFailed = 14
    case createURLRequestFailed = 15
    case downloadedFileMoveFailed = 16
    case urlRequestValidationFailed = 17
}
