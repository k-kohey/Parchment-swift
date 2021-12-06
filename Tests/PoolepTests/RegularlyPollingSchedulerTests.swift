//
//  RegularlyPollingSchedulerTests.swift
//  
//
//  Created by k-kohey on 2021/12/06.
//

import XCTest
@testable import Poolep

class RegularlyPollingSchedulerTests: XCTestCase {
    func testSchedule() throws {
        let scheduler = RegularlyPollingScheduler(timeInterval: 0.1)
        let buffer = EventQueueMock()
        let event = ExpandableLoggingEvent(eventName: "hoge", parameters: [:])
        let exp = expectation(description: "wait")
        
        var result: [BufferRecord] = []
        scheduler.schedule(with: .init(buffer)) { record in
            result = record
            exp.fulfill()
        }
        buffer.enqueue(.init(destination: "hoge", event: event, timestamp: Date()))
        
        wait(for: [exp], timeout: 1.1)
        XCTAssertEqual(event.eventName, result.first?.eventName)
        XCTAssertTrue(NSDictionary(dictionary: event.parameters).isEqual(to: result.first?.parameters))
    }
}
