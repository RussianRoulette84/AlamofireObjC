import Foundation
import Alamofire

/// Converts between an ObjC `NSDictionary<NSString*,NSString*>` and Alamofire `HTTPHeaders`.
enum AFOHeaders {

    static func make(from dictionary: [String: String]?) -> HTTPHeaders? {
        guard let dictionary = dictionary, !dictionary.isEmpty else { return nil }
        return HTTPHeaders(dictionary)
    }

    static func dictionary(from headers: HTTPHeaders?) -> [String: String] {
        guard let headers = headers else { return [:] }
        return headers.dictionary
    }
}
