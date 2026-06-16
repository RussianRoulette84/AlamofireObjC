import Foundation
import Alamofire

/// Block-driven bridge for Alamofire's `RedirectHandler`.
///
/// The block receives the proposed redirect request and the response that triggered it, and
/// returns the request to follow — or nil to refuse the redirect.
@objc(AFORedirectHandler)
public final class AFORedirectHandler: NSObject, RedirectHandler, @unchecked Sendable {

    private let block: (URLRequest, HTTPURLResponse) -> URLRequest?

    @objc public init(block: @escaping (URLRequest, HTTPURLResponse) -> URLRequest?) {
        self.block = block
        super.init()
    }

    var handler: RedirectHandler { self }

    public func task(_ task: URLSessionTask,
                     willBeRedirectedTo request: URLRequest,
                     for response: HTTPURLResponse,
                     completion: @escaping (URLRequest?) -> Void) {
        completion(block(request, response))
    }
}
