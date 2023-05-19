//
//  BufferedEventFlushScheduler.swift
//
//
//  Created by k-kohey on 2021/10/08.
//
import Foundation

public protocol BufferedEventFlushScheduler: Sendable {
    func schedule(with buffer: TrackingEventBuffer) async -> AsyncThrowingStream<[Payload], Error>
}
