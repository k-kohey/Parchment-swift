//
//  File.swift
//
//
//  Created by k-kohey on 2021/10/08.
//
import Foundation

public protocol BufferdEventFlushScheduler {
    func schedule(with buffer: TrackingEventBufferAdapter, didFlush: @escaping ([BufferRecord])->())
}

extension BufferdEventFlushScheduler {
    func schedule(with buffer: TrackingEventBufferAdapter) -> AsyncThrowingStream<[BufferRecord], Error> {
        AsyncThrowingStream { continuation in
            schedule(with: buffer) {
                continuation.yield($0)
            }
        }
    }
}
