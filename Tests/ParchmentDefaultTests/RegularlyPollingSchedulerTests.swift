//
//  RegularlyPollingSchedulerTests.swift
//
//
//  Created by k-kohey on 2021/12/06.
//

import Foundation
@testable import Parchment
@testable import ParchmentDefault
import XCTest

final class EventQueueMock: TrackingEventBuffer, @unchecked Sendable {
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

@MainActor
class RegularlyPollingSchedulerTests: XCTestCase {
    func testSchedule() throws {
        let scheduler = RegularlyPollingScheduler(timeInterval: 1)
        let buffer = EventQueueMock()
        let event = TrackingEvent(eventName: "hoge", parameters: [:])

        Task {
            for try await result in await scheduler.schedule(with: buffer) {
                XCTAssertEqual(event.eventName, result.first?.eventName)
                XCTAssertTrue(NSDictionary(dictionary: event.parameters).isEqual(to: result.first?.parameters ?? [:]))
            }
        }
        buffer.save([.init(destination: "hoge", event: event, timestamp: Date())])
    }
}
