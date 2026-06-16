import Foundation
import Alamofire

/// Factory for per-host TLS trust evaluators (certificate pinning, public-key pinning,
/// disabled, or default validation). Wrap one per host into an `AFOServerTrustManager`.
@objc(AFOServerTrustPolicy)
public final class AFOServerTrustPolicy: NSObject {

    let evaluator: ServerTrustEvaluating

    init(evaluator: ServerTrustEvaluating) {
        self.evaluator = evaluator
        super.init()
    }

    /// Pin against the given DER-encoded certificates.
    @objc public static func pinnedCertificates(_ derCertificates: [Data],
                                                acceptSelfSigned: Bool,
                                                performDefaultValidation: Bool,
                                                validateHost: Bool) -> AFOServerTrustPolicy {
        let certs = derCertificates.compactMap { SecCertificateCreateWithData(nil, $0 as CFData) }
        let evaluator = PinnedCertificatesTrustEvaluator(certificates: certs,
                                                         acceptSelfSignedCertificates: acceptSelfSigned,
                                                         performDefaultValidation: performDefaultValidation,
                                                         validateHost: validateHost)
        return AFOServerTrustPolicy(evaluator: evaluator)
    }

    /// Pin against the public keys contained in the given DER-encoded certificates.
    @objc public static func pinnedPublicKeys(fromDERCertificates derCertificates: [Data],
                                              performDefaultValidation: Bool,
                                              validateHost: Bool) -> AFOServerTrustPolicy {
        let keys = derCertificates
            .compactMap { SecCertificateCreateWithData(nil, $0 as CFData) }
            .compactMap { $0.af.publicKey }
        let evaluator = PublicKeysTrustEvaluator(keys: keys,
                                                 performDefaultValidation: performDefaultValidation,
                                                 validateHost: validateHost)
        return AFOServerTrustPolicy(evaluator: evaluator)
    }

    /// Load `.cer` files from a bundle and pin against them.
    @objc public static func pinnedCertificates(inBundle bundle: Bundle,
                                                acceptSelfSigned: Bool) -> AFOServerTrustPolicy {
        let evaluator = PinnedCertificatesTrustEvaluator(certificates: bundle.af.certificates,
                                                         acceptSelfSignedCertificates: acceptSelfSigned,
                                                         performDefaultValidation: true,
                                                         validateHost: true)
        return AFOServerTrustPolicy(evaluator: evaluator)
    }

    /// Standard system validation (chain + host).
    @objc public static func defaultValidation(validateHost: Bool) -> AFOServerTrustPolicy {
        AFOServerTrustPolicy(evaluator: DefaultTrustEvaluator(validateHost: validateHost))
    }

    /// Disable evaluation for a host (testing only — never ship).
    @objc public static func disabled() -> AFOServerTrustPolicy {
        AFOServerTrustPolicy(evaluator: DisabledTrustEvaluator())
    }
}
