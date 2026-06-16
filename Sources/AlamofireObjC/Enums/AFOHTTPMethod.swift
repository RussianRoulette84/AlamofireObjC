import Foundation
import Alamofire

/// Objective-C-visible HTTP method. Alamofire's `HTTPMethod` is a Swift struct (not an
/// enum), so it cannot cross to ObjC directly — this NS_ENUM maps to/from its raw values.
@objc(AFOHTTPMethod)
public enum AFOHTTPMethod: Int {
    case get
    case post
    case put
    case delete
    case patch
    case head
    case options
    case connect
    case trace
    case query

    /// Bridge into Alamofire's method struct.
    var alamofire: HTTPMethod {
        switch self {
        case .get: return .get
        case .post: return .post
        case .put: return .put
        case .delete: return .delete
        case .patch: return .patch
        case .head: return .head
        case .options: return .options
        case .connect: return .connect
        case .trace: return .trace
        case .query: return .query
        }
    }

    init(alamofire method: HTTPMethod) {
        switch method {
        case .post: self = .post
        case .put: self = .put
        case .delete: self = .delete
        case .patch: self = .patch
        case .head: self = .head
        case .options: self = .options
        case .connect: self = .connect
        case .trace: self = .trace
        case .query: self = .query
        default: self = .get
        }
    }
}

/// String <-> method helpers for callers that already hold a verb string (e.g. "POST").
@objc(AFOHTTPMethodBridge)
public final class AFOHTTPMethodBridge: NSObject {
    @objc public static func method(fromString string: String) -> AFOHTTPMethod {
        AFOHTTPMethod(alamofire: HTTPMethod(rawValue: string.uppercased()))
    }

    @objc public static func string(from method: AFOHTTPMethod) -> String {
        method.alamofire.rawValue
    }
}
