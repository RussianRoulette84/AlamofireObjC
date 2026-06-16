import Foundation
import Alamofire

/// Selects how request parameters are encoded. Maps to Alamofire's classic
/// `ParameterEncoding` family (URL / JSON / PropertyList), which takes `[String: Any]`
/// parameters and bridges cleanly from `NSDictionary`.
@objc(AFOParameterEncoding)
public enum AFOParameterEncoding: Int {
    /// URLEncoding.default — query string for GET/HEAD/DELETE, body otherwise.
    case URLDefault
    /// URLEncoding(destination: .queryString) — always in the URL query.
    case URLQueryString
    /// URLEncoding(destination: .httpBody) — always in the body.
    case URLHTTPBody
    /// JSONEncoding.default.
    case JSON
    /// Property-list body, XML format.
    case propertyListXML
    /// Property-list body, binary format.
    case propertyListBinary

    /// Build the concrete Alamofire encoder.
    func makeEncoding() -> ParameterEncoding {
        switch self {
        case .URLDefault:
            return URLEncoding.default
        case .URLQueryString:
            return URLEncoding(destination: .queryString)
        case .URLHTTPBody:
            return URLEncoding(destination: .httpBody)
        case .JSON:
            return JSONEncoding.default
        case .propertyListXML:
            return AFOPlistEncoding(format: .xml)
        case .propertyListBinary:
            return AFOPlistEncoding(format: .binary)
        }
    }
}
