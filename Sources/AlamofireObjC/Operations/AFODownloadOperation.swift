import Foundation
import Alamofire

/// An `NSOperation` wrapping a single download, for use in an `NSOperationQueue`. The
/// download is created lazily in `main()`; `userInfo` is echoed back through the handlers.
@objc(AFODownloadOperation)
public final class AFODownloadOperation: AFOAsynchronousOperation, @unchecked Sendable {

    public typealias Success = (URLSessionTask?, URL?, Any?) -> Void
    public typealias Failure = (URLSessionTask?, NSError, Any?) -> Void

    private let builder: () -> AFODownloadRequest
    private let progress: ((Progress) -> Void)?
    private let success: Success?
    private let failure: Failure?

    private var afoRequest: AFODownloadRequest?

    init(builder: @escaping () -> AFODownloadRequest,
         userInfo: Any?,
         progress: ((Progress) -> Void)?,
         success: Success?,
         failure: Failure?) {
        self.builder = builder
        self.progress = progress
        self.success = success
        self.failure = failure
        super.init()
        self.userInfo = userInfo
    }

    /// Download to a destination chosen by `destination`.
    @objc public static func operation(session: AFOSession,
                                       URLString: String,
                                       method: AFOHTTPMethod,
                                       parameters: [String: Any]?,
                                       encoding: AFOParameterEncoding,
                                       headers: [String: String]?,
                                       destination: ((URL, HTTPURLResponse) -> URL)?,
                                       userInfo: Any?,
                                       progress: ((Progress) -> Void)?,
                                       success: Success?,
                                       failure: Failure?) -> AFODownloadOperation {
        AFODownloadOperation(builder: {
            session.download(URLString, method: method, parameters: parameters,
                             encoding: encoding, headers: headers, destination: destination)
        }, userInfo: userInfo, progress: progress, success: success, failure: failure)
    }

    /// Resume a cancelled download from its resume data.
    @objc public static func resumeOperation(session: AFOSession,
                                             resumeData: Data,
                                             destination: ((URL, HTTPURLResponse) -> URL)?,
                                             userInfo: Any?,
                                             progress: ((Progress) -> Void)?,
                                             success: Success?,
                                             failure: Failure?) -> AFODownloadOperation {
        AFODownloadOperation(builder: {
            session.downloadResuming(with: resumeData, destination: destination)
        }, userInfo: userInfo, progress: progress, success: success, failure: failure)
    }

    public override func main() {
        let request = builder()
        afoRequest = request
        if let progress = progress { request.downloadProgress(progress) }

        request.responseURL { [weak self] fileURL, _, error in
            guard let self = self else { return }
            let task = self.afoRequest?.task
            if let error = error {
                self.failure?(task, error, self.userInfo)
            } else {
                self.success?(task, fileURL, self.userInfo)
            }
            self.completeOperation()
        }
    }

    public override func cancel() {
        super.cancel()
        afoRequest?.cancelProducingResumeData(false, handler: nil)
    }

    @objc public var request: AFODownloadRequest? { afoRequest }
}
