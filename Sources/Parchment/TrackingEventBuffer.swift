//
//  TrackingEventBuffer.swift
//
//
//  Created by k-kohey on 2021/12/29.
//

import Foundation

public protocol TrackingEventBuffer {
    func save(_ event: [BufferRecord])
    func load(limit: Int64) -> [BufferRecord]
    func count() -> Int
}

extension TrackingEventBuffer {
    func load() -> [BufferRecord] {
        load(limit: -1)
    }
}

public final actor TrackingEventBufferAdapter {
    private let buffer: any TrackingEventBuffer

    init(_ buffer: some TrackingEventBuffer) {
        self.buffer = buffer
    }

    public func save(_ event: [BufferRecord]) {
        buffer.save(event)
    }

    public func load(limit: Int64 = -1) -> [BufferRecord] {
        buffer.load(limit: limit)
    }

    public func count() -> Int {
        buffer.count()
    }
}
