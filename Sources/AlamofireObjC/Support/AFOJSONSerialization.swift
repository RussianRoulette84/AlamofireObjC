import Foundation

/// JSON helpers built on `Foundation.JSONSerialization`.
///
/// The bridge deliberately does NOT use Alamofire's deprecated `responseJSON` (removed in
/// Alamofire 6). Building JSON here also lets us reproduce AFNetworking's
/// `removesKeysWithNullValues` behaviour — recursively stripping `NSNull` from the parsed
/// object.
enum AFOJSONSerialization {

    /// Parse response `Data` into a JSON object (NSDictionary / NSArray / value).
    /// - Parameter stripsNulls: when true, every `NSNull` is removed from dictionaries and arrays.
    static func jsonObject(from data: Data, stripsNulls: Bool) throws -> Any {
        let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        return stripsNulls ? stripNulls(from: object) : object
    }

    /// Recursively remove NSNull values from dictionaries and arrays.
    static func stripNulls(from object: Any) -> Any {
        if let dict = object as? [String: Any] {
            var result: [String: Any] = [:]
            for (key, value) in dict {
                if value is NSNull { continue }
                result[key] = stripNulls(from: value)
            }
            return result
        }
        if let array = object as? [Any] {
            return array.compactMap { element -> Any? in
                if element is NSNull { return nil }
                return stripNulls(from: element)
            }
        }
        return object
    }
}
