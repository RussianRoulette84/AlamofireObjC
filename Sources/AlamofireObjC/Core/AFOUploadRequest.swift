import Foundation
import Alamofire

/// Chainable wrapper around Alamofire's `UploadRequest`.
///
/// `UploadRequest` is a `DataRequest` subclass, so this inherits the full response/validation
/// /progress surface from `AFORequest`. Upload progress is reported via `uploadProgress:`.
@objc(AFOUploadRequest)
public final class AFOUploadRequest: AFORequest {

    let uploadRequest: UploadRequest

    init(uploadRequest: UploadRequest) {
        self.uploadRequest = uploadRequest
        super.init(request: uploadRequest)
    }
}
