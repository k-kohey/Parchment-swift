//
//  TrackingEventBuffer.swift
//
//
//  Created by k-kohey on 2021/12/29.
//

import Foundation

public protocol TrackingEventBuffer: Sendable {
    func save(_ event: [BufferRecord]) async
    func load(limit: Int64) async -> [BufferRecord]
    func count() async -> Int
}

public extension TrackingEventBuffer {
    func load() async -> [BufferRecord] {
        await load(limit: -1)
    }
}
