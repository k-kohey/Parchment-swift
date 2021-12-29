//
//  RegularlyPollingSchedulerTests.swift
//  
//
//  Created by k-kohey on 2021/12/06.
//

import XCTest
import Foundation
@testable import ParchmentDefault
@testable import Parchment

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

class RegularlyPollingSchedulerTests: XCTestCase {
    func testSchedule() throws {
        let scheduler = RegularlyPollingScheduler(timeInterval: 0.1)
        let buffer = EventQueueMock()
        let event = TrackingEvent(eventName: "hoge", parameters: [:])
        let exp = expectation(description: "wait")
        
        var result: [BufferRecord] = []
        scheduler.schedule(with: .init(buffer)) { record in
            result = record
            exp.fulfill()
        }
        buffer.save([.init(destination: "hoge", event: event, timestamp: Date())])
        
        wait(for: [exp], timeout: 1.1)
        XCTAssertEqual(event.eventName, result.first?.eventName)
        XCTAssertTrue(NSDictionary(dictionary: event.parameters).isEqual(to: result.first?.parameters ?? [:]))
    }
}
