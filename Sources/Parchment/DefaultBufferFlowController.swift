//
//  RegularlyPollingScheduler.swift
//
//
//  Created by k-kohey on 2021/12/29.
//

import Foundation
import ParchmentCore

public final class DefaultBufferFlowController: BufferFlowController, Sendable {
    let pollingInterval: UInt
    let maxBufferSize: Int
    let inputAccumulationLimit: Int
    let delayInputLimit: TimeInterval

    @MainActor private var inputAccumulationPayloads: [Payload] = []

    private var bufferTask: Task<Void, Error>? = nil

    public init(
        pollingInterval: UInt,
        maxBufferSize: Int = .max,
        inputAccumulationLimit: Int = 5,
        delayInputLimit: TimeInterval = 30
    ) {
        self.pollingInterval = pollingInterval
        self.maxBufferSize = maxBufferSize
        self.inputAccumulationLimit = inputAccumulationLimit
        self.delayInputLimit = delayInputLimit
    }

    public func input<T: LogBuffer>(
        _ events: [Payload], with buffer: T
    ) async throws {
        @Sendable @MainActor func save() async throws {
            try await buffer.enqueue(inputAccumulationPayloads)
            inputAccumulationPayloads = []
        }

        bufferTask?.cancel()
        Task { @MainActor in
            inputAccumulationPayloads += events
            if inputAccumulationLimit < inputAccumulationPayloads.count {
                try await save()
            }
            else {
                bufferTask = Task {
                    try await Task.sleep(nanoseconds: UInt64(delayInputLimit) * 1000_000_000)

                    if Task.isCancelled {
                        return
                    }

                    try await save()
                }
            }
        }
    }

    public func output<T: LogBuffer>(
        with buffer: T
    ) async -> AsyncThrowingStream<[Payload], Error> {
        AsyncThrowingStream { continuation in
            Task {
                while !Task.isCancelled {
                    let payloads = try? await buffer.load()
                    continuation.yield(payloads ?? [])
                    do {
                        try await Task.sleep(
                            nanoseconds: UInt64(pollingInterval) * 1000_000_000
                        )
                    } catch {
                        break
                    }
                }
                continuation.finish()
            }

            Task {
                while !Task.isCancelled {
                    let count = try? await buffer.count()
                    if maxBufferSize < (count ?? 0) {
                        let payloads = try? await buffer.load()
                        continuation.yield(payloads ?? [])
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
