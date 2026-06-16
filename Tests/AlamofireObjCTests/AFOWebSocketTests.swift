import XCTest
@testable import AlamofireObjC

final class AFOWebSocketTests: XCTestCase {

    private var server: EchoWebSocketServer!
    private var socket: AFOWebSocketTask!

    override func setUpWithError() throws {
        server = try EchoWebSocketServer()
        try server.start()
    }

    override func tearDown() {
        socket?.close(code: 1000, reason: nil)
        socket = nil
        server.stop()
        server = nil
        super.tearDown()
    }

    func testTextRoundTrip() {
        let url = URL(string: "ws://localhost:\(server.port)/")!
        socket = AFOWebSocketTask(url: url)
        let exp = expectation(description: "echo-text")

        socket.onText = { text in
            XCTAssertEqual(text, "hello")
            exp.fulfill()
        }
        socket.resume()
        socket.sendText("hello", completion: { error in XCTAssertNil(error) })

        wait(for: [exp], timeout: 10)
    }

    func testBinaryRoundTrip() {
        let url = URL(string: "ws://localhost:\(server.port)/")!
        socket = AFOWebSocketTask(url: url)
        let exp = expectation(description: "echo-binary")
        let payload = Data([0x01, 0x02, 0x03])

        socket.onBinary = { data in
            XCTAssertEqual(data, payload)
            exp.fulfill()
        }
        socket.resume()
        socket.sendData(payload, completion: nil)

        wait(for: [exp], timeout: 10)
    }

    func testPingGetsResponseWithoutError() {
        let url = URL(string: "ws://localhost:\(server.port)/")!
        socket = AFOWebSocketTask(url: url)
        let exp = expectation(description: "ping")
        socket.resume()
        socket.sendPing { error in
            XCTAssertNil(error, "echo server auto-replies pings")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }

    func testClientCloseFiresOnClose() {
        let url = URL(string: "ws://localhost:\(server.port)/")!
        socket = AFOWebSocketTask(url: url)
        let exp = expectation(description: "close")
        socket.onClose = { code, _ in
            XCTAssertEqual(code, 1000)
            exp.fulfill()
        }
        socket.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { self.socket.close(code: 1000, reason: nil) }
        wait(for: [exp], timeout: 10)
    }
}
