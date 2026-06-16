import Foundation
import Alamofire

/// A proper Alamofire `ResponseSerializer` for JSON — replaces hand-rolled `JSONSerialization`
/// so we keep empty-response handling, data preprocessing, and participation in retry. Adds
/// optional recursive `NSNull` stripping (AFNetworking `removesKeysWithNullValues` parity).
struct AFOJSONResponseSerializer: ResponseSerializer {

    let stripsNulls: Bool
    let dataPreprocessor: DataPreprocessor = PassthroughPreprocessor()
    let emptyResponseCodes: Set<Int> = AFOJSONResponseSerializer.defaultEmptyResponseCodes
    let emptyRequestMethods: Set<HTTPMethod> = AFOJSONResponseSerializer.defaultEmptyRequestMethods

    func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> Any {
        if let error = error { throw error }

        guard var data = data, !data.isEmpty else {
            // Empty body on an allowed empty-response code/method → NSNull, else fail.
            guard emptyResponseAllowed(forRequest: request, response: response) else {
                throw AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
            }
            return NSNull()
        }

        data = try dataPreprocessor.preprocess(data)
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            return stripsNulls ? AFOJSONSerialization.stripNulls(from: json) : json
        } catch {
            throw AFError.responseSerializationFailed(reason: .jsonSerializationFailed(error: error))
        }
    }
}
