import XCTest
@testable import AlamofireObjC

final class AFOReachabilityTests: XCTestCase {

    func testMonitoringReportsAStatus() {
        let manager = AFOReachabilityManager()
        let exp = expectation(description: "status")
        exp.assertForOverFulfill = false

        manager.statusChangeBlock = { status in
            XCTAssertNotEqual(status, .unknown, "monitor should resolve to a concrete status")
            if manager.isReachable {
                // A reachable path is, by definition, already connected.
                XCTAssertFalse(manager.requiresConnection)
            }
            _ = (manager.isConstrained, manager.isExpensive)   // readable while monitoring
            exp.fulfill()
        }
        manager.startMonitoring()
        wait(for: [exp], timeout: 10)
        manager.stopMonitoring()
    }

    func testNotificationPosts() {
        let manager = AFOReachabilityManager()
        let exp = expectation(forNotification: AFOReachabilityManager.didChangeNotification,
                              object: manager, handler: nil)
        manager.startMonitoring()
        wait(for: [exp], timeout: 10)
        manager.stopMonitoring()
    }
}
