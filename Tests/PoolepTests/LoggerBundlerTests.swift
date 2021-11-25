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

class LoggerBundlerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSend_whenPolicyIsImmediately() async throws {
        let logger = LoggerMock()
        let buffer = EventQueueMock()
        let bundler = LoggerBundler(components: [logger], buffer: buffer)
        bundler.startLogging()
        
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
    
    func testSend_whenPolicyIsBufferingFirst() async throws {
        let logger = LoggerMock()
        let buffer = EventQueueMock()
        let bundler = LoggerBundler(components: [logger], buffer: buffer)
        bundler.startLogging()
        
        await bundler.send(
            ExpandableLoggingEvent(eventName: "hoge", parameters: [:]),
            with: .init(policy: .bufferingFirst)
        )
        
        XCTAssertEqual(buffer.count(), 1)
    }
}
