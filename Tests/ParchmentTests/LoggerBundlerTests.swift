//
//  LoggerBundlerTests.swift
//  
//
//  Created by k-kohey on 2021/11/22.
//

import XCTest
@testable import Parchment

private extension LoggerComponentID {
    static let a = LoggerComponentID("A")
    static let b = LoggerComponentID("B")
}

final class LoggerA: LoggerComponent {
    static let id: LoggerComponentID = .a
    
    var _send: (()->(Bool))?
    
    func send(_: [LoggerSendable]) async -> Bool {
        _send?() ?? true
    }
}

final class LoggerB: LoggerComponent {
    static let id: LoggerComponentID = .b
    
    var _send: (()->(Bool))?
    
    func send(_: [LoggerSendable]) async -> Bool {
        _send?() ?? true
    }
}

final class EventQueueMock: TrackingEventBuffer {
    private var records: [BufferRecord] = []
    
    func save(_ e: [BufferRecord]) {
        records += e
    }
    
    func load(limit: Int64) -> [BufferRecord] {
        let count = 0 < limit ? Int(limit) : records.count
        return (0..<min(count, records.count)).reduce([]) { result, _ in
            result + [dequeue()].compactMap { $0 }
        }
    }
    
    func count() -> Int {
        records.count
    }
    
    private func dequeue() -> BufferRecord? {
        defer {
            if !records.isEmpty {
                records.removeFirst()
            }
        }
        return records.first
    }
}

final class BufferedEventFlushStrategyMock: BufferedEventFlushScheduler {
    private var buffer: TrackingEventBufferAdapter?
    
    private var continuation: AsyncThrowingStream<[BufferRecord], Error>.Continuation?
    
    func schedule(with buffer: TrackingEventBufferAdapter) async -> AsyncThrowingStream<[BufferRecord], Error> {
        self.buffer = buffer
        return .init { continuation in
            self.continuation = continuation
        }
    }
    
    func cancel() {
        
    }
    
    func flush() async {
        await continuation?.yield(buffer!.load(limit: .max))
    }
}

class LoggerBundlerTests: XCTestCase {
    func testSendImmediately() async throws {
        let logger = LoggerA()
        let buffer = EventQueueMock()
        let bundler = LoggerBundler(components: [logger], buffer: buffer, loggingStrategy: BufferedEventFlushStrategyMock())
        
        var didSend = false
        logger._send = {
            didSend = true
            return didSend
        }
        
        await bundler.send(
            TrackingEvent(eventName: "hoge", parameters: [:]),
            with: .init(policy: .immediately)
        )
        
        XCTAssertTrue(didSend)
    }
    
    func testSendAfterBuffering() async throws {
        let logger = LoggerA()
        let buffer = EventQueueMock()
        let strategy = BufferedEventFlushStrategyMock()
        let bundler = LoggerBundler(
            components: [logger],
            buffer: buffer,
            loggingStrategy: strategy
        )
        
        bundler.startLogging()
        
        await bundler.send(
            TrackingEvent(eventName: "hoge", parameters: [:]),
            with: .init(policy: .bufferingFirst)
        )
        await bundler.send(
            TrackingEvent(eventName: "fuga", parameters: [:]),
            with: .init(policy: .bufferingFirst)
        )
        XCTAssertEqual(buffer.count(), 2)
        
        await strategy.flush()
        
        XCTAssertEqual(buffer.count(), 0)
    }
    
    func testSendOnlyOneSideLogger() async throws {
        let loggerA = LoggerA()
        let loggerB = LoggerB()
        let buffer = EventQueueMock()
        let bundler = LoggerBundler(
            components: [loggerA, loggerB],
            buffer: buffer,
            loggingStrategy: BufferedEventFlushStrategyMock()
        )
        
        var didSendFromLoggerA = false
        loggerA._send = {
            didSendFromLoggerA = true
            return didSendFromLoggerA
        }
        var didSendFromLoggerB = false
        loggerB._send = {
            didSendFromLoggerB = true
            return didSendFromLoggerB
        }
        
        await bundler.send(
            TrackingEvent(eventName: "hoge", parameters: [:]),
            with: .init(policy: .immediately, scope: .only([loggerA.id]))
        )
        
        XCTAssertEqual(didSendFromLoggerA, true)
        XCTAssertEqual(didSendFromLoggerB, false)
    }
}
