//
//  BufferedEventFlushScheduler.swift
//
//
//  Created by k-kohey on 2021/10/08.
//
import Foundation

public protocol BufferFlowController: Sendable {
    func input<T: LogBuffer>(_: [Payload], with buffer: T) async throws
    func output<T: LogBuffer>(with: T) async -> AsyncThrowingStream<[Payload], Error>
}
