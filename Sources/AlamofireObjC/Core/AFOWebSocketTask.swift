import Foundation

/// Objective-C WebSocket client built on Apple's stable `URLSessionWebSocketTask`.
///
/// Deliberately NOT routed through Alamofire — its `WebSocketRequest` is `@_spi`/experimental
/// and documented to break. This gives the same capability on public API. Owns its own
/// `URLSession`, so retain the task while the socket is open.
@objc(AFOWebSocketTask)
public final class AFOWebSocketTask: NSObject {

    private let task: URLSessionWebSocketTask
    private let ownedSession: URLSession

    private let lock = NSLock()
    private var _didClose = false
    private var _onText: ((String) -> Void)?
    private var _onBinary: ((Data) -> Void)?
    private var _onClose: ((Int, Data?) -> Void)?
    private var _onError: ((NSError) -> Void)?

    /// Fires for each received text message.
    @objc public var onText: ((String) -> Void)? {
        get { lock.lock(); defer { lock.unlock() }; return _onText }
        set { lock.lock(); _onText = newValue; lock.unlock() }
    }
    /// Fires for each received binary message.
    @objc public var onBinary: ((Data) -> Void)? {
        get { lock.lock(); defer { lock.unlock() }; return _onBinary }
        set { lock.lock(); _onBinary = newValue; lock.unlock() }
    }
    /// Fires once when the socket closes (close code + optional reason).
    @objc public var onClose: ((Int, Data?) -> Void)? {
        get { lock.lock(); defer { lock.unlock() }; return _onClose }
        set { lock.lock(); _onClose = newValue; lock.unlock() }
    }
    /// Fires on a transport/protocol error.
    @objc public var onError: ((NSError) -> Void)? {
        get { lock.lock(); defer { lock.unlock() }; return _onError }
        set { lock.lock(); _onError = newValue; lock.unlock() }
    }

    /// Open a socket to `url` with optional headers and configuration. Designated `@objc`
    /// initializer (a public one is required for ObjC to see `initWithURL:` variants).
    @objc public init(url: URL,
                      headers: [String: String]?,
                      configuration: URLSessionConfiguration) {
        var request = URLRequest(url: url)
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        let session = URLSession(configuration: configuration)
        self.ownedSession = session
        self.task = session.webSocketTask(with: request)
        super.init()
    }

    @objc(initWithURL:)
    public convenience init(url: URL) {
        self.init(url: url, headers: nil, configuration: .default)
    }


    // MARK: - Lifecycle

    /// Connect and start receiving.
    @objc public func resume() {
        task.resume()
        receiveNext()
    }

    /// Gracefully close (RFC 6455 close code, e.g. 1000 = normal).
    @objc public func close(code: Int, reason: Data?) {
        let closeCode = URLSessionWebSocketTask.CloseCode(rawValue: code) ?? .normalClosure
        task.cancel(with: closeCode, reason: reason)
        fireCloseOnce(code: code, reason: reason)
    }

    /// Deliver `onClose` at most once (a client close and the receive-loop failure both reach it).
    private func fireCloseOnce(code: Int, reason: Data?) {
        lock.lock()
        if _didClose { lock.unlock(); return }
        _didClose = true
        lock.unlock()
        onClose?(code, reason)
    }

    // MARK: - Send

    @objc public func sendText(_ text: String, completion: ((NSError?) -> Void)?) {
        task.send(.string(text)) { completion?($0 as NSError?) }
    }

    @objc public func sendData(_ data: Data, completion: ((NSError?) -> Void)?) {
        task.send(.data(data)) { completion?($0 as NSError?) }
    }

    @objc public func sendPing(_ completion: ((NSError?) -> Void)?) {
        task.sendPing { completion?($0 as NSError?) }
    }

    // MARK: - Receive loop

    private func receiveNext() {
        task.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text): self.onText?(text)
                case .data(let data): self.onBinary?(data)
                @unknown default: break
                }
                self.receiveNext()
            case .failure(let error):
                // A server-initiated close surfaces here with a set closeCode.
                if self.task.closeCode != .invalid {
                    self.fireCloseOnce(code: self.task.closeCode.rawValue, reason: self.task.closeReason)
                } else {
                    self.onError?(error as NSError)
                }
            }
        }
    }
}
