//
//  BufferedEventFlushScheduler.swift
//
//
//  Created by k-kohey on 2021/10/08.
//
import Foundation

public protocol BufferedEventFlushScheduler {
    func schedule(with buffer: TrackingEventBufferAdapter) async -> AsyncThrowingStream<[BufferRecord], Error>
    func cancel()
}
