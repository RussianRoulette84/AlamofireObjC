import Foundation
import Network

/// Network reachability status.
@objc(AFOReachabilityStatus)
public enum AFOReachabilityStatus: Int {
    case unknown
    case notReachable
    case reachableViaWWAN
    case reachableViaWiFi
}

/// `AFNetworkReachabilityManager` look-alike built on `Network.framework` `NWPathMonitor`
/// (AFNetworking's reachability is gone in modern stacks). API kept close for easy migration.
@objc(AFOReachabilityManager)
public final class AFOReachabilityManager: NSObject, @unchecked Sendable {

    /// Posted whenever reachability changes. `object` is the manager.
    @objc public static let didChangeNotification = Notification.Name("AFOReachabilityDidChangeNotification")

    @objc public static let shared = AFOReachabilityManager()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.yaro.alamofireobjc.reachability")

    @objc public private(set) var status: AFOReachabilityStatus = .unknown
    @objc public var statusChangeBlock: ((AFOReachabilityStatus) -> Void)?

    @objc public var isReachable: Bool { status == .reachableViaWWAN || status == .reachableViaWiFi }
    @objc public var isReachableViaWiFi: Bool { status == .reachableViaWiFi }
    @objc public var isReachableViaWWAN: Bool { status == .reachableViaWWAN }

    /// Path is constrained (e.g. Low Data Mode). Updated while monitoring.
    @objc public private(set) var isConstrained: Bool = false
    /// Path is expensive (cellular / personal hotspot).
    @objc public private(set) var isExpensive: Bool = false
    /// Connectivity would require establishing a connection (not currently satisfied).
    @objc public private(set) var requiresConnection: Bool = false

    @objc public func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let newStatus = Self.status(from: path)
            self.status = newStatus
            self.isConstrained = path.isConstrained
            self.isExpensive = path.isExpensive
            self.requiresConnection = (path.status == .requiresConnection)
            DispatchQueue.main.async {
                self.statusChangeBlock?(newStatus)
                NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
            }
        }
        monitor.start(queue: queue)
    }

    @objc public func stopMonitoring() {
        monitor.cancel()
    }

    private static func status(from path: NWPath) -> AFOReachabilityStatus {
        guard path.status == .satisfied else { return .notReachable }
        if path.usesInterfaceType(.cellular) { return .reachableViaWWAN }
        return .reachableViaWiFi
    }
}
