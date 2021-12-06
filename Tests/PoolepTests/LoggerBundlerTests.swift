//
//  LoggerBundlerTests.swift
//  
//
//  Created by k-kohey on 2021/11/22.
//

import XCTest
@testable import Poolep

private extension LoggerComponentID {
    static let mock = LoggerComponentID("mock")
}

final class LoggerMock: LoggerComponent {
    static let id: LoggerComponentID = .mock
    
    var _send: (()->(Bool))?
    
    func send(_: Loggable) async -> Bool {
        _send?() ?? true
    }
}

final class EventQueueMock: TrackingEventBuffer {
    private var records: [BufferRecord] = []
    
    func enqueue(_ e: BufferRecord) {
        records.append(e)
    }
    
    func dequeue() -> BufferRecord? {
        defer {
            if !records.isEmpty {
                records.removeFirst()
            }
        }
        return records.first
    }
    
    func dequeue(limit: Int64) -> [BufferRecord] {
        (0..<min(Int(limit), records.count)).reduce([]) { result, _ in
            result + [dequeue()].compactMap { $0 }
        }
    }
    
    func count() -> Int {
        records.count
    }
}

final class BufferdEventFlushStorategyMock: BufferdEventFlushScheduler {
    private var didFlush: (([BufferRecord]) -> ())? = nil
    private var buffer: TrackingEventBufferAdapter?
    
    func schedule(with buffer: TrackingEventBufferAdapter, didFlush: @escaping ([BufferRecord]) -> ()) {
        self.didFlush = didFlush
        self.buffer = buffer
    }
    
    func flush() async {
        await didFlush!(buffer!.dequeue(limit: .max))
        
    }
}

class LoggerBundlerTests: XCTestCase {
    func testSendImmediately() async throws {
        let logger = LoggerMock()
        let buffer = EventQueueMock()
        let bundler = LoggerBundler(components: [logger], buffer: buffer)
        
        var didSend = false
        logger._send = {
            didSend = true
            return didSend
        }
        
        await bundler.send(
            ExpandableLoggingEvent(eventName: "hoge", parameters: [:]),
            with: .init(policy: .immediately)
        )
        
        XCTAssertTrue(didSend)
    }
    
    func testSendAfterBuffering() async throws {
        let logger = LoggerMock()
        let buffer = EventQueueMock()
        let storategy = BufferdEventFlushStorategyMock()
        let bundler = LoggerBundler(
            components: [logger],
            buffer: buffer,
            loggingStorategy: storategy
        )
        
        bundler.startLogging()
        
        await bundler.send(
            ExpandableLoggingEvent(eventName: "hoge", parameters: [:]),
            with: .init(policy: .bufferingFirst)
        )
        await bundler.send(
            ExpandableLoggingEvent(eventName: "fuga", parameters: [:]),
            with: .init(policy: .bufferingFirst)
        )
        XCTAssertEqual(buffer.count(), 2)
        
        await storategy.flush()
        
        XCTAssertEqual(buffer.count(), 0)
    }
}
