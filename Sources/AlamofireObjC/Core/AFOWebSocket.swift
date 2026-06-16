import Foundation

/// Objective-C factory for ``AFOWebSocketTask``.
///
/// `AFOWebSocketTask`'s own initializers are not reliably emitted to the generated ObjC header
/// (Swift omits creation members for it), so this small factory class — whose members emit
/// normally — is the supported way to open a socket from Objective-C:
/// `AFOWebSocketTask *ws = [AFOWebSocket open:url];`
@objc(AFOWebSocket)
public final class AFOWebSocket: NSObject {

    /// Open a socket to `url` with the default configuration.
    @objc public static func open(_ url: URL) -> AFOWebSocketTask {
        AFOWebSocketTask(url: url)
    }

    /// Open a socket with optional headers and a custom configuration.
    @objc public static func open(_ url: URL,
                                  headers: [String: String]?,
                                  configuration: URLSessionConfiguration) -> AFOWebSocketTask {
        AFOWebSocketTask(url: url, headers: headers, configuration: configuration)
    }
}
