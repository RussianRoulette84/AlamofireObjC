import Foundation
import Alamofire

/// AFNetworking-style multipart POST: `POST:parameters:headers:constructingBodyWithBlock:...`.
public extension AFOHTTPSessionManager {

    @discardableResult
    @objc func post(_ URLString: String,
                    parameters: [String: Any]?,
                    headers: [String: String]?,
                    constructingBody block: @escaping (AFOMultipartFormData) -> Void,
                    progress: ((Progress) -> Void)?,
                    success: Success?,
                    failure: Failure?) -> AFOUploadRequest {
        var merged = defaultHeaders
        headers?.forEach { merged[$0.key] = $0.value }

        let form = AFOMultipartFormData()
        // Fold only scalar parameters (String/NSNumber/Bool) into the body as form fields.
        // Complex values (dictionaries, arrays, data) must be appended explicitly via the
        // block — silently stringifying them produced garbage parts. NSNumber renders without
        // a wrapping description (e.g. "3", not "Optional(3)").
        parameters?.forEach { key, value in
            let scalar: String?
            switch value {
            case let string as String: scalar = string
            case let number as NSNumber: scalar = number.stringValue
            default: scalar = nil
            }
            if let scalar = scalar, let data = scalar.data(using: .utf8) {
                form.appendData(data, name: key)
            }
        }
        block(form)

        let request = session().uploadMultipart(form, to: resolvedURL(URLString),
                                                method: .post, headers: merged)
        request.removesKeysWithNullValues = removesKeysWithNullValues
        if let progress = progress { request.uploadProgress(progress) }

        request.responseJSON { response in
            let task = request.task
            if let error = response.error { failure?(task, error) } else { success?(task, response.value) }
        }
        return request
    }
}
