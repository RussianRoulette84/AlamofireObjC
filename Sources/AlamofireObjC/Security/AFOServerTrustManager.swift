import Foundation
import Alamofire

/// Maps hostnames to `AFOServerTrustPolicy` evaluators. Pass to `AFOSession`'s configured init.
@objc(AFOServerTrustManager)
public final class AFOServerTrustManager: NSObject {

    let manager: ServerTrustManager

    /// - Parameters:
    ///   - policies: host → policy. e.g. @{ @"api.example.com": [AFOServerTrustPolicy ...] }.
    ///   - allHostsMustBeEvaluated: when YES, a request to a host without a policy fails.
    @objc public init(policies: [String: AFOServerTrustPolicy], allHostsMustBeEvaluated: Bool) {
        let evaluators = policies.mapValues { $0.evaluator }
        self.manager = ServerTrustManager(allHostsMustBeEvaluated: allHostsMustBeEvaluated,
                                          evaluators: evaluators)
        super.init()
    }
}
