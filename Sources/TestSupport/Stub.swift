//
//  Stub.swift
//  
//
//  Created by Kohei Kawaguchi on 2023/05/17.
//

import Parchment

private extension LoggerComponentID {
    static let a = LoggerComponentID("A")
    static let b = LoggerComponentID("B")
}

public final class LoggerA: LoggerComponent, @unchecked Sendable {
    public static let id: LoggerComponentID = .a

    public var _send: (([LoggerSendable]) -> (Bool))?

    public func send(_ events: [LoggerSendable]) async -> Bool {
        _send?(events) ?? true
    }
}

public final class LoggerB: LoggerComponent, @unchecked Sendable {
    public static let id: LoggerComponentID = .b

    public var _send: (([LoggerSendable]) -> (Bool))?

    public func send(_ events: [LoggerSendable]) async -> Bool {
        _send?(events) ?? true
    }
}

public final class EventQueueMock: LogBuffer, @unchecked Sendable {
    private var records: [Payload] = []

    public func enqueue(_ e: [Payload]) {
        records += e
    }

    public func dequeue(limit: Int?) async throws -> [Parchment.Payload] {
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

    public func count() -> Int {
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

public final class BufferedEventFlushStrategyMock: BufferFlowController, @unchecked Sendable {
    private var buffer: LogBuffer?

    private var continuation: AsyncThrowingStream<[Payload], Error>.Continuation?

    public func input<T: LogBuffer>(_ payloads: [Payload], with buffer: T) async throws {
        try await buffer.enqueue(payloads)
    }

    public func output<T: LogBuffer>(with buffer: T) async -> AsyncThrowingStream<[Payload], Error> {
        self.buffer = buffer
        return .init { continuation in
            self.continuation = continuation
        }
    }

    public func cancel() {}

    public func flush() async {
        let events = try! await buffer!.load()
        continuation?.yield(events)
    }
}
