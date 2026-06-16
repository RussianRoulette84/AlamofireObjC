import Foundation
import Alamofire

/// AFNetworking-style SSL pinning mode.
@objc(AFOSSLPinningMode)
public enum AFOSSLPinningMode: Int {
    case none
    case publicKey
    case certificate
}

/// AFNetworking `AFSecurityPolicy` look-alike. Configure it on `AFOHTTPSessionManager`; it is
/// translated into an `AFOServerTrustManager` for the manager's host.
@objc(AFOSecurityPolicy)
public final class AFOSecurityPolicy: NSObject {

    @objc public var pinningMode: AFOSSLPinningMode = .none
    /// DER-encoded certificates to pin against.
    @objc public var pinnedCertificates: [Data] = []
    @objc public var allowInvalidCertificates: Bool = false
    @objc public var validatesDomainName: Bool = true

    @objc public override init() { super.init() }

    @objc public static func policy(with mode: AFOSSLPinningMode) -> AFOSecurityPolicy {
        let policy = AFOSecurityPolicy()
        policy.pinningMode = mode
        return policy
    }

    /// Build a trust manager scoped to `host`, or nil for default system behaviour.
    func trustManager(forHost host: String) -> AFOServerTrustManager? {
        let policy: AFOServerTrustPolicy
        switch pinningMode {
        case .none:
            if allowInvalidCertificates {
                policy = .disabled()
            } else {
                return nil // standard system validation
            }
        case .certificate:
            policy = .pinnedCertificates(pinnedCertificates,
                                         acceptSelfSigned: allowInvalidCertificates,
                                         performDefaultValidation: !allowInvalidCertificates,
                                         validateHost: validatesDomainName)
        case .publicKey:
            policy = .pinnedPublicKeys(fromDERCertificates: pinnedCertificates,
                                       performDefaultValidation: !allowInvalidCertificates,
                                       validateHost: validatesDomainName)
        }
        return AFOServerTrustManager(policies: [host: policy], allHostsMustBeEvaluated: false)
    }
}
