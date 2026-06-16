import Foundation
import Network

/// Minimal local WebSocket echo server (Network.framework `NWProtocolWebSocket`) for testing
/// `AFOWebSocketTask` against a real handshake — echoes every text/binary frame back.
final class EchoWebSocketServer {

    enum ServerError: Error { case noPort }

    private let listener: NWListener
    private let queue = DispatchQueue(label: "com.yaro.alamofireobjc.wsserver")
    private(set) var port: UInt16 = 0

    init() throws {
        let parameters = NWParameters.tcp
        let wsOptions = NWProtocolWebSocket.Options()
        wsOptions.autoReplyPing = true
        parameters.defaultProtocolStack.applicationProtocols.insert(wsOptions, at: 0)
        parameters.allowLocalEndpointReuse = true
        listener = try NWListener(using: parameters, on: .any)
    }

    func start() throws {
        let ready = DispatchSemaphore(value: 0)
        listener.stateUpdateHandler = { [weak self] state in
            if case .ready = state, let assigned = self?.listener.port?.rawValue {
                self?.port = assigned
                ready.signal()
            }
        }
        listener.newConnectionHandler = { [weak self] connection in
            connection.start(queue: self?.queue ?? .global())
            self?.receive(on: connection)
        }
        listener.start(queue: queue)
        if ready.wait(timeout: .now() + 5) == .timedOut { throw ServerError.noPort }
    }

    func stop() { listener.cancel() }

    private func receive(on connection: NWConnection) {
        connection.receiveMessage { [weak self] content, context, _, error in
            guard let self = self else { return }
            if let content = content, let context = context,
               let metadata = context.protocolMetadata(definition: NWProtocolWebSocket.definition)
                   as? NWProtocolWebSocket.Metadata {
                let opcode: NWProtocolWebSocket.Opcode = (metadata.opcode == .text) ? .text : .binary
                let replyMetadata = NWProtocolWebSocket.Metadata(opcode: opcode)
                let replyContext = NWConnection.ContentContext(identifier: "echo", metadata: [replyMetadata])
                connection.send(content: content, contentContext: replyContext, isComplete: true,
                                completion: .contentProcessed { _ in })
            }
            if error == nil { self.receive(on: connection) }
        }
    }
}
