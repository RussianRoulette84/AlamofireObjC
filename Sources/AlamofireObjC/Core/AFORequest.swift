import Foundation
import Alamofire

/// Chainable Objective-C wrapper around Alamofire's `DataRequest`.
///
/// Every response/configuration method returns `self` so calls can be chained from ObjC:
/// `[[[session request:url] validate] responseJSON:^(AFOResponse *r) { ... }];`
@objc(AFORequest)
public class AFORequest: NSObject {

    let request: DataRequest

    /// When YES, `responseJSON:` strips NSNull values from the parsed object
    /// (AFNetworking `removesKeysWithNullValues` parity). Default NO.
    @objc public var removesKeysWithNullValues: Bool = false

    /// Queue the response blocks are delivered on. Defaults to main (AFNetworking parity).
    @objc public var completionQueue: DispatchQueue = .main

    init(request: DataRequest) {
        self.request = request
        super.init()
    }

    /// The underlying session task once created.
    @objc public var task: URLSessionTask? { request.task }

    /// Stable identifier for this request.
    @objc public var requestID: String { request.id.uuidString }

    // MARK: - Response handlers

    /// Parse the body as JSON via a proper Alamofire `ResponseSerializer` (empty-response
    /// handling + retry participation). `value` is an NSDictionary/NSArray (or NSNull for an
    /// allowed empty body).
    @discardableResult
    @objc public func responseJSON(_ handler: @escaping (AFOResponse) -> Void) -> Self {
        let serializer = AFOJSONResponseSerializer(stripsNulls: removesKeysWithNullValues)
        request.response(queue: completionQueue, responseSerializer: serializer) { resp in
            handler(AFOResponse.make(from: resp, value: resp.value))
        }
        return self
    }

    /// Deliver the raw body data.
    @discardableResult
    @objc public func responseData(_ handler: @escaping (AFOResponse) -> Void) -> Self {
        request.responseData(queue: completionQueue) { resp in
            handler(AFOResponse.make(from: resp, value: resp.value))
        }
        return self
    }

    /// Deliver the body decoded as a UTF-8 string.
    @discardableResult
    @objc public func responseString(_ handler: @escaping (AFOResponse) -> Void) -> Self {
        request.responseString(queue: completionQueue) { resp in
            handler(AFOResponse.make(from: resp, value: resp.value))
        }
        return self
    }

    /// Parse JSON, then map it into a caller model before delivery. `map` receives the parsed
    /// JSON object and returns any model object (or nil); `handler` gets the mapped model plus
    /// the full response (for status/error inspection).
    @discardableResult
    @objc public func responseObject(map: @escaping (Any) -> Any?,
                                     handler: @escaping (Any?, AFOResponse) -> Void) -> Self {
        responseJSON { response in
            let model = response.value.flatMap { map($0) }
            handler(model, response)
        }
        return self
    }

    // MARK: - Validation

    @discardableResult
    @objc public func validate() -> Self {
        request.validate()
        return self
    }

    @discardableResult
    @objc public func validateWithConfig(_ config: AFOValidationConfig) -> Self {
        if let codes = config.statusCodeArray { request.validate(statusCode: codes) }
        if let types = config.acceptableContentTypes { request.validate(contentType: types) }
        if config.statusCodeArray == nil && config.acceptableContentTypes == nil { request.validate() }
        return self
    }

    // MARK: - Authentication

    @discardableResult
    @objc public func authenticateWithUsername(_ username: String, password: String) -> Self {
        request.authenticate(username: username, password: password)
        return self
    }

    @discardableResult
    @objc public func authenticateWithCredential(_ credential: URLCredential) -> Self {
        request.authenticate(with: credential)
        return self
    }

    // MARK: - Progress

    @discardableResult
    @objc public func uploadProgress(_ handler: @escaping (Progress) -> Void) -> Self {
        request.uploadProgress(queue: completionQueue, closure: handler)
        return self
    }

    @discardableResult
    @objc public func downloadProgress(_ handler: @escaping (Progress) -> Void) -> Self {
        request.downloadProgress(queue: completionQueue, closure: handler)
        return self
    }

    // MARK: - Debug

    /// Asynchronously produce the cURL command for this request (touches the credential store).
    @discardableResult
    @objc public func cURLDescription(_ handler: @escaping (String) -> Void) -> Self {
        request.cURLDescription { handler($0) }
        return self
    }

    // MARK: - Lifecycle

    @discardableResult @objc public func resume() -> Self { request.resume(); return self }
    @discardableResult @objc public func suspend() -> Self { request.suspend(); return self }
    @discardableResult @objc public func cancel() -> Self { request.cancel(); return self }
}
