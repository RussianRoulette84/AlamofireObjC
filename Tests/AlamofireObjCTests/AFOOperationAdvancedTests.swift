import XCTest
@testable import AlamofireObjC

final class AFOOperationAdvancedTests: XCTestCase {

    override func tearDown() { StubURLProtocol.reset(); super.tearDown() }

    private func makeOp(_ session: AFOSession, tag: String, record: @escaping (String) -> Void) -> AFORequestOperation {
        AFORequestOperation.operation(session: session, method: .get,
                                      URLString: "https://example.com/\(tag)",
                                      parameters: nil, encoding: .URLDefault, headers: nil, userInfo: tag,
                                      uploadProgress: nil, downloadProgress: nil,
                                      success: { _, _, info in record(info as? String ?? "?") },
                                      failure: { _, _, info in record(info as? String ?? "?") })
    }

    func testDependencyEnforcesOrderOnConcurrentQueue() {
        StubURLProtocol.handler = { req in TestSupport.jsonResponse(for: req, body: Data("{}".utf8)) }
        let session = TestSupport.stubbedSession()
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 4   // concurrent, but dependency must still order

        var order: [String] = []
        let lock = NSLock()
        let record: (String) -> Void = { tag in lock.lock(); order.append(tag); lock.unlock() }

        let first = makeOp(session, tag: "first", record: record)
        let second = makeOp(session, tag: "second", record: record)
        second.addDependency(first)

        let done = expectation(description: "done")
        let barrier = BlockOperation { done.fulfill() }
        barrier.addDependency(second)
        queue.addOperations([second, first], waitUntilFinished: false)
        queue.addOperation(barrier)

        wait(for: [done], timeout: 10)
        XCTAssertEqual(order.firstIndex(of: "first")! < order.firstIndex(of: "second")!, true)
    }

    func testConcurrentQueueCompletesAllOperations() {
        StubURLProtocol.handler = { req in TestSupport.jsonResponse(for: req, body: Data("{}".utf8)) }
        let session = TestSupport.stubbedSession()
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 4

        var completed = 0
        let lock = NSLock()
        var exps: [XCTestExpectation] = []
        var ops: [AFORequestOperation] = []

        for i in 0..<8 {
            let exp = expectation(description: "op\(i)")
            exps.append(exp)
            let op = makeOp(session, tag: "op\(i)") { _ in
                lock.lock(); completed += 1; lock.unlock()
                exp.fulfill()
            }
            ops.append(op)
        }
        queue.addOperations(ops, waitUntilFinished: false)

        wait(for: exps, timeout: 15)
        XCTAssertEqual(completed, 8)
        XCTAssertTrue(ops.allSatisfy { $0.isFinished })
    }
}
