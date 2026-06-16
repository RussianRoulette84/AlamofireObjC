import Foundation
import Alamofire

/// Block-driven bridge for Alamofire's `EventMonitor`. Attach at session creation to observe
/// request lifecycle — also used by the compat facade to print cURL for every request.
@objc(AFOEventMonitor)
public final class AFOEventMonitor: NSObject, EventMonitor, @unchecked Sendable {

    // Blocks are read on `queue` and written by callers, so guard them with a lock —
    // making `@unchecked Sendable` correct rather than a hand-wave.
    private let lock = NSLock()
    private var _didCreateTask: ((URLSessionTask) -> Void)?
    private var _didFinishRequest: ((URLRequest?, HTTPURLResponse?, NSError?) -> Void)?
    private var _didResolveCURL: ((String) -> Void)?

    /// Fires when a request's URLSessionTask is created.
    @objc public var didCreateTask: ((URLSessionTask) -> Void)? {
        get { lock.lock(); defer { lock.unlock() }; return _didCreateTask }
        set { lock.lock(); _didCreateTask = newValue; lock.unlock() }
    }

    /// Fires when a request finishes (success or failure).
    @objc public var didFinishRequest: ((URLRequest?, HTTPURLResponse?, NSError?) -> Void)? {
        get { lock.lock(); defer { lock.unlock() }; return _didFinishRequest }
        set { lock.lock(); _didFinishRequest = newValue; lock.unlock() }
    }

    /// Fires with the resolved cURL description once the request has a URLRequest.
    @objc public var didResolveCURL: ((String) -> Void)? {
        get { lock.lock(); defer { lock.unlock() }; return _didResolveCURL }
        set { lock.lock(); _didResolveCURL = newValue; lock.unlock() }
    }

    /// Alamofire delivers events on this queue.
    public let queue = DispatchQueue(label: "com.yaro.alamofireobjc.eventmonitor")

    @objc public override init() {
        super.init()
    }

    public func request(_ request: Request, didCreateTask task: URLSessionTask) {
        didCreateTask?(task)
    }

    public func requestDidFinish(_ request: Request) {
        let response = request.response
        let error = request.error.map { AFOError.error(from: $0) }
        didFinishRequest?(request.request, response, error)
    }

    public func request(_ request: Request, didCreateURLRequest urlRequest: URLRequest) {
        guard didResolveCURL != nil else { return }
        request.cURLDescription { [weak self] curl in self?.didResolveCURL?(curl) }
    }
}
