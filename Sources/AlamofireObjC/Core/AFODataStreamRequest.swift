import Foundation
import Alamofire

/// Chainable wrapper around Alamofire's `DataStreamRequest`.
///
/// This is the Objective-C, block-based equivalent of Alamofire's Combine stream publisher:
/// `onStream:` fires for every chunk and once more on completion.
@objc(AFODataStreamRequest)
public final class AFODataStreamRequest: NSObject {

    let request: DataStreamRequest

    /// Queue stream events are delivered on. Defaults to main.
    @objc public var completionQueue: DispatchQueue = .main

    init(request: DataStreamRequest) {
        self.request = request
        super.init()
    }

    @objc public var task: URLSessionTask? { request.task }
    @objc public var requestID: String { request.id.uuidString }

    /// Observe the stream. For each chunk `completed` is NO and `chunk` holds the bytes; the
    /// final call has `completed` = YES (with `error` set if the stream failed).
    @discardableResult
    @objc public func onStream(_ handler: @escaping (_ chunk: Data?, _ completed: Bool, _ error: NSError?) -> Void) -> AFODataStreamRequest {
        request.responseStream(on: completionQueue) { stream in
            switch stream.event {
            case .stream(let result):
                // Failure is `Never` for an unserialized stream, so success is the only case.
                if case let .success(data) = result { handler(data, false, nil) }
            case .complete(let completion):
                handler(nil, true, completion.error.map { AFOError.error(from: $0) })
            }
        }
        return self
    }

    @discardableResult @objc public func resume() -> AFODataStreamRequest { request.resume(); return self }
    @discardableResult @objc public func cancel() -> AFODataStreamRequest { request.cancel(); return self }
}
