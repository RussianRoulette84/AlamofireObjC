import Foundation
import Alamofire

/// Factories for upload operations. Uploads share the data-request response shape, so these
/// return `AFORequestOperation` (JSON success/failure with `userInfo` passthrough) — the
/// request is built lazily so the operation queue gates concurrency.
@objc(AFOUploadOperation)
public final class AFOUploadOperation: NSObject {

    /// Upload in-memory data.
    @objc public static func dataOperation(session: AFOSession,
                                           data: Data,
                                           URLString: String,
                                           method: AFOHTTPMethod,
                                           headers: [String: String]?,
                                           userInfo: Any?,
                                           progress: ((Progress) -> Void)?,
                                           success: AFORequestOperation.Success?,
                                           failure: AFORequestOperation.Failure?) -> AFORequestOperation {
        AFORequestOperation(builder: {
            session.uploadData(data, to: URLString, method: method, headers: headers)
        }, userInfo: userInfo, uploadProgress: progress, downloadProgress: nil,
           success: success, failure: failure)
    }

    /// Upload a file from disk.
    @objc public static func fileOperation(session: AFOSession,
                                           fileURL: URL,
                                           URLString: String,
                                           method: AFOHTTPMethod,
                                           headers: [String: String]?,
                                           userInfo: Any?,
                                           progress: ((Progress) -> Void)?,
                                           success: AFORequestOperation.Success?,
                                           failure: AFORequestOperation.Failure?) -> AFORequestOperation {
        AFORequestOperation(builder: {
            session.uploadFile(fileURL, to: URLString, method: method, headers: headers)
        }, userInfo: userInfo, uploadProgress: progress, downloadProgress: nil,
           success: success, failure: failure)
    }

    /// Upload a multipart/form-data body.
    @objc public static func multipartOperation(session: AFOSession,
                                                form: AFOMultipartFormData,
                                                URLString: String,
                                                method: AFOHTTPMethod,
                                                headers: [String: String]?,
                                                userInfo: Any?,
                                                progress: ((Progress) -> Void)?,
                                                success: AFORequestOperation.Success?,
                                                failure: AFORequestOperation.Failure?) -> AFORequestOperation {
        AFORequestOperation(builder: {
            session.uploadMultipart(form, to: URLString, method: method, headers: headers)
        }, userInfo: userInfo, uploadProgress: progress, downloadProgress: nil,
           success: success, failure: failure)
    }

    /// Upload from an input stream.
    @objc public static func streamOperation(session: AFOSession,
                                             stream: InputStream,
                                             URLString: String,
                                             method: AFOHTTPMethod,
                                             headers: [String: String]?,
                                             userInfo: Any?,
                                             progress: ((Progress) -> Void)?,
                                             success: AFORequestOperation.Success?,
                                             failure: AFORequestOperation.Failure?) -> AFORequestOperation {
        AFORequestOperation(builder: {
            session.uploadStream(stream, to: URLString, method: method, headers: headers)
        }, userInfo: userInfo, uploadProgress: progress, downloadProgress: nil,
           success: success, failure: failure)
    }
}
