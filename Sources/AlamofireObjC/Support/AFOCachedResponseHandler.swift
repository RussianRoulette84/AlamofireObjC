import Foundation
import Alamofire

/// Block-driven bridge for Alamofire's `CachedResponseHandler`.
///
/// The block receives the response the system proposes to cache and returns the response to
/// actually cache — or nil to skip caching.
@objc(AFOCachedResponseHandler)
public final class AFOCachedResponseHandler: NSObject, CachedResponseHandler, @unchecked Sendable {

    private let block: (CachedURLResponse) -> CachedURLResponse?

    @objc public init(block: @escaping (CachedURLResponse) -> CachedURLResponse?) {
        self.block = block
        super.init()
    }

    var handler: CachedResponseHandler { self }

    public func dataTask(_ task: URLSessionDataTask,
                         willCacheResponse response: CachedURLResponse,
                         completion: @escaping (CachedURLResponse?) -> Void) {
        completion(block(response))
    }
}
