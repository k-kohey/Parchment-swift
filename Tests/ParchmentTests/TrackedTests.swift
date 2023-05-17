//
//  TrackedTests.swift
//  
//
//  Created by Kohei Kawaguchi on 2023/05/17.
//

import XCTest
@testable import Parchment

private let loggerA = LoggerA()
private var bundler = LoggerBundler(
    components: [loggerA],
    buffer: EventQueueMock(),
    loggingStrategy: BufferedEventFlushStrategyMock()
)

private struct State: Equatable {
    let name: String
    let age: Int
}

final class TrackedTests: XCTestCase {
    @Tracked(logger: bundler) private var state: State? = nil
    @Tracked(logger: bundler, scope: \.?.name) private var scopedState: State? = nil

    func testTracked() async throws {
        var result: LoggerSendable?
        loggerA._send = { events in
            result = events.first
            return true
        }

        state = .init(name: "Taro", age: 16)

        while result == nil {
            await Task.yield()
        }

        XCTAssertEqual(result?.event.eventName, "PropetyTrackingEvent")

        XCTAssertEqual(result?.event.parameters["updaetd_value"] as? State, state)
    }

    func testScopedTracked() async throws {
        var result: LoggerSendable?
        loggerA._send = { events in
            result = events.first
            return true
        }

        scopedState = .init(name: "Taro", age: 16)

        while result == nil {
            await Task.yield()
        }

        XCTAssertEqual(result?.event.eventName, "PropetyTrackingEvent")
        XCTAssertEqual(result!.event.parameters["updaetd_value"] as? String, "Taro")
    }
}

