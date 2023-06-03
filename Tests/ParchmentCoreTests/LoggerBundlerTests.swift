//
//  LoggerBundlerTests.swift
//
//
//  Created by k-kohey on 2021/11/22.
//

@testable import ParchmentCore
@testable import TestSupport
import XCTest

@MainActor
class LoggerBundlerTests: XCTestCase {
    func testSendImmediately() async throws {
        let logger = LoggerA()
        let buffer = EventQueueMock()
        let bundler = LoggerBundler(
            components: [logger], buffer: buffer, bufferFlowController: BufferedEventFlushStrategyMock()
        )

        var didSend = false
        logger._send = { _ in
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
            bufferFlowController: strategy
        )

        _ = await bundler.startLogging()
        await bundler.send(
            TrackingEvent(eventName: "hoge", parameters: [:]),
            with: .init(policy: .bufferingFirst)
        )

        XCTAssertEqual(buffer.count(), 1, "Buffre should retain events")

        await strategy.flush()

        XCTAssertEqual(buffer.count(), 0, "Buffre should flush events")
    }

    func testSendOnlyOneSideLogger() async throws {
        let loggerA = LoggerA()
        let loggerB = LoggerB()
        let buffer = EventQueueMock()
        let bundler = LoggerBundler(
            components: [loggerA, loggerB],
            buffer: buffer,
            bufferFlowController: BufferedEventFlushStrategyMock()
        )

        var didSendFromLoggerA = false
        loggerA._send = { _ in
            didSendFromLoggerA = true
            return didSendFromLoggerA
        }
        var didSendFromLoggerB = false
        loggerB._send = { _ in
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
