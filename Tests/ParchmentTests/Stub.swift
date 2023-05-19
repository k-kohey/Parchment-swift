//
//  Stub.swift
//  
//
//  Created by Kohei Kawaguchi on 2023/05/17.
//

@testable import Parchment

private extension LoggerComponentID {
    static let a = LoggerComponentID("A")
    static let b = LoggerComponentID("B")
}

final class LoggerA: LoggerComponent, @unchecked Sendable {
    static let id: LoggerComponentID = .a

    var _send: (([LoggerSendable]) -> (Bool))?

    func send(_ events: [LoggerSendable]) async -> Bool {
        _send?(events) ?? true
    }
}

final class LoggerB: LoggerComponent, @unchecked Sendable {
    static let id: LoggerComponentID = .b

    var _send: (([LoggerSendable]) -> (Bool))?

    func send(_ events: [LoggerSendable]) async -> Bool {
        _send?(events) ?? true
    }
}

final class EventQueueMock: LogBuffer, @unchecked Sendable {
    private var records: [Payload] = []

    func save(_ e: [Payload]) {
        records += e
    }

    func load(limit: Int?) async throws -> [Parchment.Payload] {
        let count: Int
        if let limit {
            count = limit
        } else {
            count = records.count
        }
        return (0 ..< min(count, records.count)).reduce([]) { result, _ in
            result + [dequeue()].compactMap { $0 }
        }
    }

    func count() -> Int {
        records.count
    }

    private func dequeue() -> Payload? {
        defer {
            if !records.isEmpty {
                records.removeFirst()
            }
        }
        return records.first
    }
}

final class BufferedEventFlushStrategyMock: BufferFlowController, @unchecked Sendable {
    private var buffer: LogBuffer?

    private var continuation: AsyncThrowingStream<[Payload], Error>.Continuation?

    func input<T: LogBuffer>(_ payloads: [Payload], with buffer: T) async throws {
        try await buffer.save(payloads)
    }

    func output<T: LogBuffer>(with buffer: T) async -> AsyncThrowingStream<[Payload], Error> {
        self.buffer = buffer
        return .init { continuation in
            self.continuation = continuation
        }
    }

    func cancel() {}

    func flush() async {
        let events = try! await buffer!.load()
        continuation?.yield(events)
    }
}
