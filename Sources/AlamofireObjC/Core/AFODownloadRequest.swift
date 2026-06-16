import Foundation
import Alamofire

/// Chainable Objective-C wrapper around Alamofire's `DownloadRequest`.
@objc(AFODownloadRequest)
public final class AFODownloadRequest: NSObject {

    let request: DownloadRequest

    /// Queue response blocks are delivered on. Defaults to main.
    @objc public var completionQueue: DispatchQueue = .main

    init(request: DownloadRequest) {
        self.request = request
        super.init()
    }

    @objc public var task: URLSessionTask? { request.task }
    @objc public var requestID: String { request.id.uuidString }

    // MARK: - Response handlers

    /// Deliver the final on-disk file URL (and any error).
    @discardableResult
    @objc public func responseURL(_ handler: @escaping (URL?, HTTPURLResponse?, NSError?) -> Void) -> AFODownloadRequest {
        request.response(queue: completionQueue) { resp in
            handler(resp.fileURL, resp.response, resp.error.map { AFOError.error(from: $0) })
        }
        return self
    }

    /// Deliver the downloaded bytes in memory.
    @discardableResult
    @objc public func responseData(_ handler: @escaping (Data?, HTTPURLResponse?, NSError?) -> Void) -> AFODownloadRequest {
        request.responseData(queue: completionQueue) { resp in
            handler(resp.value, resp.response, resp.error.map { AFOError.error(from: $0) })
        }
        return self
    }

    // MARK: - Validation / progress / debug

    @discardableResult
    @objc public func validate() -> AFODownloadRequest { request.validate(); return self }

    @discardableResult
    @objc public func downloadProgress(_ handler: @escaping (Progress) -> Void) -> AFODownloadRequest {
        request.downloadProgress(queue: completionQueue, closure: handler)
        return self
    }

    @discardableResult
    @objc public func cURLDescription(_ handler: @escaping (String) -> Void) -> AFODownloadRequest {
        request.cURLDescription { handler($0) }
        return self
    }

    // MARK: - Lifecycle

    @discardableResult @objc public func resume() -> AFODownloadRequest { request.resume(); return self }
    @discardableResult @objc public func suspend() -> AFODownloadRequest { request.suspend(); return self }

    /// Cancel the download. When `producingResumeData` is YES, the resume data (if any) is
    /// delivered to `handler` so the download can be continued later.
    @discardableResult
    @objc public func cancelProducingResumeData(_ producing: Bool,
                                                handler: ((Data?) -> Void)?) -> AFODownloadRequest {
        if producing, let handler = handler {
            // Async variant: resume data is delivered once the task finishes cancelling.
            request.cancel(byProducingResumeData: { data in handler(data) })
        } else if producing {
            request.cancel(producingResumeData: true)
        } else {
            request.cancel()
        }
        return self
    }

    /// Resume data captured if the download was cancelled with `producingResumeData`.
    @objc public var resumeData: Data? { request.resumeData }
}
