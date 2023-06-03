//
//  RegularlyPollingSchedulerTests.swift
//
//
//  Created by k-kohey on 2021/12/06.
//

import Foundation
@testable import Parchment
import XCTest

final class EventQueueMock: LogBuffer, @unchecked Sendable {
    private var records: [Payload] = []

    func enqueue(_ e: [Payload]) {
        records += e
    }

    func dequeue(limit: Int?) async throws -> [Payload] {
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
    func testInput() async throws {
        let controller = DefaultBufferFlowController(
            pollingInterval: 1,
            inputAccumulationLimit: 3
        )
        let buffer = EventQueueMock()

        try await controller.input(
            [
                .init(
                    destination: "hoge",
                    event: TrackingEvent(eventName: "hoge", parameters: [:]),
                    timestamp: .init()
                )
            ],
            with: buffer
        )
        XCTAssertEqual(buffer.count(), 0)

        try await controller.input(
            .init(repeating: .init(
                destination: "hoge",
                event: TrackingEvent(eventName: "hoge", parameters: [:]),
                timestamp: .init()
            ), count: 3),
            with: buffer
        )

        await Task.yield()
        XCTAssertEqual(buffer.count(), 4)
    }

    func testInput_with_delay() async throws {
        let delayInputLimit: TimeInterval = 1
        let controller = DefaultBufferFlowController(
            pollingInterval: 1,
            delayInputLimit: delayInputLimit
        )
        let buffer = EventQueueMock()

        try await controller.input(
            [
                .init(
                    destination: "hoge",
                    event: TrackingEvent(eventName: "hoge", parameters: [:]),
                    timestamp: .init()
                )
            ],
            with: buffer
        )
        XCTAssertEqual(buffer.count(), 0)

        try await Task.sleep(
            nanoseconds: UInt64(delayInputLimit + 1) * 1000_000_000
        )

        XCTAssertEqual(buffer.count(), 1)
    }

    func testOutput() async throws {
        let controller = DefaultBufferFlowController(pollingInterval: 1)
        let buffer = EventQueueMock()
        let event = TrackingEvent(eventName: "hoge", parameters: [:])
        var outputEvent: Payload?
        Task {
            for try await result in await controller.output(with: buffer) {
                outputEvent = result.first
                return
            }
        }
        buffer.enqueue([.init(destination: "hoge", event: event, timestamp: Date())])

        while outputEvent == nil {
            await Task.yield()
        }

        XCTAssertEqual(event.eventName, outputEvent?.eventName)
        XCTAssertTrue(
            NSDictionary(dictionary: event.parameters).isEqual(to: outputEvent?.parameters ?? [:])
        )
    }
}
