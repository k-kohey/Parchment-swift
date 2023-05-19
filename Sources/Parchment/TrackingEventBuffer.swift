//
//  TrackingEventBuffer.swift
//
//
//  Created by k-kohey on 2021/12/29.
//

import Foundation

public protocol LogBuffer: Sendable {
    func save(_ event: [Payload]) async throws
    func load(limit: Int?) async throws -> [Payload]
    func count() async throws -> Int
}

public extension LogBuffer {
    func load() async throws -> [Payload] {
        try await load(limit: nil)
    }
}
