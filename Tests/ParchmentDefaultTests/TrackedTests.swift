//
//  TrackedTests.swift
//  
//
//  Created by Kohei Kawaguchi on 2023/05/17.
//

import XCTest
@testable import Parchment
@testable import ParchmentDefault
@testable import TestSupport

private let loggerA = LoggerA()
private var bundler = LoggerBundler(
    components: [loggerA],
    buffer: EventQueueMock(),
    bufferFlowController: BufferedEventFlushStrategyMock()
)

private struct State: Equatable {
    let name: String
    let age: Int
}

final class TrackedTests: XCTestCase {
    @Tracked(
        name: "PropetyTrackingEvent", with: bundler, option: .init(policy: .immediately)
    ) private var state: State? = nil
    @Tracked(
        name: "PropetyTrackingEvent", with: bundler, scope: \.?.name, option: .init(policy: .immediately)
    ) private var scopedState: State? = nil

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

