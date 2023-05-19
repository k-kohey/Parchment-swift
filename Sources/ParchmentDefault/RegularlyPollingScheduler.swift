//
//  RegularlyPollingScheduler.swift
//
//
//  Created by k-kohey on 2021/12/29.
//

import Foundation
import Parchment

public struct RegularlyPollingScheduler: BufferedEventFlushScheduler, Sendable {
    let timeInterval: UInt
    let limitOnNumberOfEvent: Int

    public init(
        timeInterval: UInt,
        limitOnNumberOfEvent: Int = .max
    ) {
        self.timeInterval = timeInterval
        self.limitOnNumberOfEvent = limitOnNumberOfEvent
    }

    public func schedule(with buffer: TrackingEventBuffer) async -> AsyncThrowingStream<[BufferRecord], Error> {
        AsyncThrowingStream { continuation in
            Task {
                while !Task.isCancelled {
                    let records = try? await buffer.load()
                    continuation.yield(records ?? [])
                    do {
                        try await Task.sleep(nanoseconds: UInt64(timeInterval) * 1000_000_000)
                    } catch {
                        break
                    }
                }
                continuation.finish()
            }

            Task {
                while !Task.isCancelled {
                    let count = try? await buffer.count()
                    if limitOnNumberOfEvent < (count ?? 0) {
                        let records = try? await buffer.load()
                        continuation.yield(records ?? [])
                    }
                    do {
                        try await Task.sleep(nanoseconds: 1000_000_000)
                    } catch {
                        break
                    }
                }
                continuation.finish()
            }
        }
    }
}
