import Foundation
import Alamofire

/// The rich response object delivered to the chainable layer's handlers, e.g.
/// `[[session request:url] responseJSON:^(AFOResponse *r) { ... }]`.
///
/// Mirrors Alamofire's `DataResponse` but with only ObjC-representable members. `value`
/// holds the serialized payload (parsed JSON object, string, or raw NSData depending on the
/// handler used); `error` is non-nil on failure.
@objc(AFOResponse)
public final class AFOResponse: NSObject {

    /// The URL request sent to the server.
    @objc public let request: URLRequest?

    /// The HTTP response received, if any.
    @objc public let response: HTTPURLResponse?

    /// The raw body data.
    @objc public let data: Data?

    /// The serialized value (NSDictionary/NSArray for JSON, NSString for string, NSData for data).
    @objc public let value: Any?

    /// Non-nil when the request or serialization failed.
    @objc public let error: NSError?

    /// Task metrics, when collected.
    @objc public let metrics: URLSessionTaskMetrics?

    /// Convenience accessor for the HTTP status code (0 when no response).
    @objc public var statusCode: Int { response?.statusCode ?? 0 }

    /// True when there is no error.
    @objc public var isSuccess: Bool { error == nil }

    /// `value` as a JSON object dictionary, or nil if it isn't one.
    @objc public var jsonDictionary: [String: Any]? { value as? [String: Any] }

    /// `value` as a JSON array, or nil if it isn't one.
    @objc public var jsonArray: [Any]? { value as? [Any] }

    /// `value` as a string (the serialized string, or UTF-8 decoded body as a fallback).
    @objc public var stringValue: String? {
        if let string = value as? String { return string }
        return data.flatMap { String(data: $0, encoding: .utf8) }
    }

    /// The raw body data.
    @objc public var dataValue: Data? { data }

    init(request: URLRequest?,
         response: HTTPURLResponse?,
         data: Data?,
         value: Any?,
         error: NSError?,
         metrics: URLSessionTaskMetrics?) {
        self.request = request
        self.response = response
        self.data = data
        self.value = value
        self.error = error
        self.metrics = metrics
        super.init()
    }

    /// Build from an Alamofire data response of arbitrary serialized type.
    static func make<T>(from response: DataResponse<T, AFError>, value: Any?) -> AFOResponse {
        AFOResponse(request: response.request,
                    response: response.response,
                    data: response.data,
                    value: value,
                    error: response.error.map { AFOError.error(from: $0) },
                    metrics: response.metrics)
    }
}
