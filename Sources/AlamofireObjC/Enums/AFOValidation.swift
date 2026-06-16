import Foundation

/// Describes acceptable HTTP responses. Passed to `-validateWithConfig:` on a request, or
/// used by the compat facade's response serializer. Empty/nil fields mean "use Alamofire's
/// default automatic validation" (200..<300 + the Accept header content types).
@objc(AFOValidationConfig)
public final class AFOValidationConfig: NSObject {

    /// Acceptable status codes. nil → default 200..<300.
    @objc public var acceptableStatusCodes: NSIndexSet?

    /// Acceptable content types, e.g. @[@"application/json"]. nil → derived from Accept header.
    @objc public var acceptableContentTypes: [String]?

    @objc public override init() {
        super.init()
    }

    @objc public convenience init(statusCodes: NSIndexSet?, contentTypes: [String]?) {
        self.init()
        self.acceptableStatusCodes = statusCodes
        self.acceptableContentTypes = contentTypes
    }

    /// Convenience for a contiguous status range.
    @objc public static func config(fromStatus from: Int, toStatus to: Int) -> AFOValidationConfig {
        let set = NSIndexSet(indexesIn: NSRange(location: from, length: max(0, to - from)))
        return AFOValidationConfig(statusCodes: set, contentTypes: nil)
    }

    /// Expand the index set into the [Int] Alamofire wants.
    var statusCodeArray: [Int]? {
        guard let set = acceptableStatusCodes else { return nil }
        return (set as IndexSet).map { $0 }
    }
}
