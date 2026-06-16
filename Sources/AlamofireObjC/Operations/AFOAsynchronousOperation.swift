import Foundation

/// KVO-correct concurrent `NSOperation` base for wrapping asynchronous network work in an
/// `NSOperationQueue`. Subclasses start their task in `main()` and call `completeOperation`
/// when the task finishes. Mirrors the proven AFNetworking-era pattern.
@objc(AFOAsynchronousOperation)
open class AFOAsynchronousOperation: Operation, @unchecked Sendable {

    /// Arbitrary caller context echoed back through completion handlers (e.g. an image's
    /// metadata). Preserves the AFNetworking `userInfo` passthrough contract.
    @objc open var userInfo: Any?

    private let stateLock = NSLock()
    private var _executing = false
    private var _finished = false

    open override var isAsynchronous: Bool { true }

    open override var isExecuting: Bool {
        get { stateLock.lock(); defer { stateLock.unlock() }; return _executing }
        set {
            willChangeValue(forKey: "isExecuting")
            stateLock.lock(); _executing = newValue; stateLock.unlock()
            didChangeValue(forKey: "isExecuting")
        }
    }

    open override var isFinished: Bool {
        get { stateLock.lock(); defer { stateLock.unlock() }; return _finished }
        set {
            willChangeValue(forKey: "isFinished")
            stateLock.lock(); _finished = newValue; stateLock.unlock()
            didChangeValue(forKey: "isFinished")
        }
    }

    open override func start() {
        if isCancelled {
            isFinished = true
            return
        }
        isExecuting = true
        main()
    }

    /// Subclasses override to launch their task. Must eventually call `completeOperation`.
    open override func main() {
        // Abstract — overridden by AFORequestOperation / AFOUploadOperation / AFODownloadOperation.
    }

    /// Transition the operation to finished, firing the KVO the queue depends on.
    @objc open func completeOperation() {
        isExecuting = false
        isFinished = true
    }
}
