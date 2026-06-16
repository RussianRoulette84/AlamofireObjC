import Foundation
import Alamofire

/// Upload factories — file, data, multipart and stream.
public extension AFOSession {

    /// Upload in-memory data.
    @discardableResult
    @objc func uploadData(_ data: Data,
                          to url: String,
                          method: AFOHTTPMethod,
                          headers: [String: String]?) -> AFOUploadRequest {
        let request = session.upload(data,
                                     to: url,
                                     method: method.alamofire,
                                     headers: AFOHeaders.make(from: headers))
        return AFOUploadRequest(uploadRequest: request)
    }

    /// Upload a file from disk.
    @discardableResult
    @objc func uploadFile(_ fileURL: URL,
                          to url: String,
                          method: AFOHTTPMethod,
                          headers: [String: String]?) -> AFOUploadRequest {
        let request = session.upload(fileURL,
                                     to: url,
                                     method: method.alamofire,
                                     headers: AFOHeaders.make(from: headers))
        return AFOUploadRequest(uploadRequest: request)
    }

    /// Upload a multipart/form-data body built with `AFOMultipartFormData`.
    @discardableResult
    @objc func uploadMultipart(_ form: AFOMultipartFormData,
                               to url: String,
                               method: AFOHTTPMethod,
                               headers: [String: String]?) -> AFOUploadRequest {
        let request = session.upload(multipartFormData: { form.apply(to: $0) },
                                     to: url,
                                     method: method.alamofire,
                                     headers: AFOHeaders.make(from: headers))
        return AFOUploadRequest(uploadRequest: request)
    }

    /// Upload from an input stream.
    @discardableResult
    @objc func uploadStream(_ stream: InputStream,
                            to url: String,
                            method: AFOHTTPMethod,
                            headers: [String: String]?) -> AFOUploadRequest {
        let request = session.upload(stream,
                                     to: url,
                                     method: method.alamofire,
                                     headers: AFOHeaders.make(from: headers))
        return AFOUploadRequest(uploadRequest: request)
    }
}
