import Foundation
import Alamofire

/// ObjC builder for multipart/form-data bodies.
///
/// Alamofire's `upload(multipartFormData:)` runs its builder closure lazily, so this class
/// records each append as a deferred action and replays them into the real
/// `MultipartFormData` when Alamofire asks. Never holds a stale AF reference.
@objc(AFOMultipartFormData)
public final class AFOMultipartFormData: NSObject {

    private var actions: [(MultipartFormData) -> Void] = []

    @objc public override init() {
        super.init()
    }

    /// Append in-memory data under a field name.
    @objc public func appendData(_ data: Data, name: String) {
        actions.append { $0.append(data, withName: name) }
    }

    /// Append in-memory data as a named file part with an explicit MIME type.
    @objc public func appendData(_ data: Data, name: String, fileName: String, mimeType: String) {
        actions.append { $0.append(data, withName: name, fileName: fileName, mimeType: mimeType) }
    }

    /// Append a file on disk under a field name (file name + MIME inferred).
    @objc public func appendFileURL(_ fileURL: URL, name: String) {
        actions.append { $0.append(fileURL, withName: name) }
    }

    /// Append a file on disk as a named file part with explicit metadata.
    @objc public func appendFileURL(_ fileURL: URL, name: String, fileName: String, mimeType: String) {
        actions.append { $0.append(fileURL, withName: name, fileName: fileName, mimeType: mimeType) }
    }

    /// Append a stream of a known length as a named file part.
    @objc public func appendInputStream(_ stream: InputStream,
                                        length: UInt64,
                                        name: String,
                                        fileName: String,
                                        mimeType: String) {
        actions.append { $0.append(stream, withLength: length, name: name, fileName: fileName, mimeType: mimeType) }
    }

    /// Replay all recorded appends into the real Alamofire builder.
    func apply(to form: MultipartFormData) {
        actions.forEach { $0(form) }
    }
}
