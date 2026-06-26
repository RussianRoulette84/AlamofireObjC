import Foundation
import Alamofire

/// An `NSOperation` wrapping a single data request, for use in an `NSOperationQueue`.
///
/// The underlying request is created lazily in `main()`, so the queue's
/// `maxConcurrentOperationCount` actually gates how many requests are in flight. `userInfo`
/// is echoed back through the success/failure blocks.
@objc(AFORequestOperation)
public final class AFORequestOperation: AFOAsynchronousOperation, @unchecked Sendable {

    public typealias Success = (URLSessionTask?, Any?, Any?) -> Void
    public typealias Failure = (URLSessionTask?, NSError, Any?) -> Void

    private let builder: () -> AFORequest
    private let uploadProgress: ((Progress) -> Void)?
    private let downloadProgress: ((Progress) -> Void)?
    private let success: Success?
    private let failure: Failure?

    /// Strips NSNull values from the parsed JSON when YES (AFNetworking parity).
    @objc public var removesKeysWithNullValues: Bool = false

    private var afoRequest: AFORequest?

    init(builder: @escaping () -> AFORequest,
         userInfo: Any?,
         uploadProgress: ((Progress) -> Void)?,
         downloadProgress: ((Progress) -> Void)?,
         success: Success?,
         failure: Failure?) {
        self.builder = builder
        self.uploadProgress = uploadProgress
        self.downloadProgress = downloadProgress
        self.success = success
        self.failure = failure
        super.init()
        self.userInfo = userInfo
    }

    /// Build an operation for an arbitrary HTTP request.
    @objc public static func operation(session: AFOSession,
                                       method: AFOHTTPMethod,
                                       URLString: String,
                                       parameters: Any?,
                                       encoding: AFOParameterEncoding,
                                       headers: [String: String]?,
                                       userInfo: Any?,
                                       uploadProgress: ((Progress) -> Void)?,
                                       downloadProgress: ((Progress) -> Void)?,
                                       success: Success?,
                                       failure: Failure?) -> AFORequestOperation {
        AFORequestOperation(builder: {
            // Top-level JSON array body (AFNetworking `id` parity) → manual JSON encoder.
            // Dictionaries / nil keep the original encoded path.
            if encoding == .JSON, parameters != nil, !(parameters is [String: Any]) {
                return session.requestJSONObject(URLString, method: method, jsonObject: parameters, headers: headers)
            }
            return session.request(URLString, method: method, parameters: parameters as? [String: Any],
                                   encoding: encoding, headers: headers)
        }, userInfo: userInfo,
           uploadProgress: uploadProgress, downloadProgress: downloadProgress,
           success: success, failure: failure)
    }

    public override func main() {
        let request = builder()
        request.removesKeysWithNullValues = removesKeysWithNullValues
        afoRequest = request

        if let uploadProgress = uploadProgress { request.uploadProgress(uploadProgress) }
        if let downloadProgress = downloadProgress { request.downloadProgress(downloadProgress) }

        request.responseJSON { [weak self] response in
            guard let self = self else { return }
            let task = self.afoRequest?.task
            if let error = response.error {
                self.failure?(task, error, self.userInfo)
            } else {
                self.success?(task, response.value, self.userInfo)
            }
            self.completeOperation()
        }
    }

    public override func cancel() {
        super.cancel()
        afoRequest?.cancel()
    }

    /// The live request once the operation has started.
    @objc public var request: AFORequest? { afoRequest }
}
