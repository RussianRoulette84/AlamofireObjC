import Foundation
import Alamofire

/// Property-list parameter encoding. Alamofire 5.12 dropped its built-in `PropertyListEncoding`,
/// so the bridge ships its own conformer to keep plist encoding available.
///
/// The root is always the `[String: Any]` parameters dictionary, and every value must be
/// plist-serializable (String, NSNumber, Bool, Date, Data, or nested arrays/dictionaries of
/// those). A non-plist value fails loudly with `AFError.parameterEncodingFailed` rather than
/// silently producing a broken body.
struct AFOPlistEncoding: ParameterEncoding {

    let format: PropertyListSerialization.PropertyListFormat

    func encode(_ urlRequest: any URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var request = try urlRequest.asURLRequest()
        guard let parameters = parameters else { return request }

        do {
            let data = try PropertyListSerialization.data(fromPropertyList: parameters,
                                                          format: format,
                                                          options: 0)
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("application/x-plist", forHTTPHeaderField: "Content-Type")
            }
            request.httpBody = data
        } catch {
            throw AFError.parameterEncodingFailed(reason: .customEncodingFailed(error: error))
        }
        return request
    }
}
