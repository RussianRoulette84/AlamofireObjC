import XCTest
@testable import AlamofireObjC

final class AFOOperationTests: XCTestCase {

    override func tearDown() {
        StubURLProtocol.reset()
        super.tearDown()
    }

    func testSerialQueueRunsInOrderAndEchoesUserInfo() {
        StubURLProtocol.handler = { req in
            TestSupport.jsonResponse(for: req, body: Data("{}".utf8))
        }
        let session = TestSupport.stubbedSession()
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        var order: [String] = []
        let lock = NSLock()
        var expectations: [XCTestExpectation] = []

        for index in 0..<5 {
            let tag = "op\(index)"
            let exp = expectation(description: tag)
            expectations.append(exp)
            let op = AFORequestOperation.operation(
                session: session, method: .get, URLString: "https://example.com/\(tag)",
                parameters: nil, encoding: .URLDefault, headers: nil, userInfo: tag,
                uploadProgress: nil, downloadProgress: nil,
                success: { _, _, userInfo in
                    lock.lock(); order.append(userInfo as? String ?? "?"); lock.unlock()
                    exp.fulfill()
                }, failure: { _, _, _ in exp.fulfill() })
            queue.addOperation(op)
        }

        wait(for: expectations, timeout: 10)
        XCTAssertEqual(order, ["op0", "op1", "op2", "op3", "op4"])
    }

    func testCancelBeforeStartFinishesWithoutFiring() {
        StubURLProtocol.handler = { req in TestSupport.jsonResponse(for: req, body: Data("{}".utf8)) }
        let session = TestSupport.stubbedSession()
        let queue = OperationQueue()
        queue.isSuspended = true

        let op = AFORequestOperation.operation(
            session: session, method: .get, URLString: "https://example.com/x",
            parameters: nil, encoding: .URLDefault, headers: nil, userInfo: nil,
            uploadProgress: nil, downloadProgress: nil,
            success: { _, _, _ in XCTFail("should not succeed after cancel") },
            failure: { _, _, _ in })
        queue.addOperation(op)
        op.cancel()
        queue.isSuspended = false

        let drained = expectation(description: "drained")
        queue.addBarrierBlock { drained.fulfill() }
        wait(for: [drained], timeout: 5)
        XCTAssertTrue(op.isFinished)
    }
}
