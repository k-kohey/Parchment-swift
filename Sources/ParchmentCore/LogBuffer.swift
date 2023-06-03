//
//  LogBuffer.swift
//
//
//  Created by k-kohey on 2021/12/29.
//

import Foundation

/// `LogBuffer` represents a protocol for managing Payload objects.
///
/// By implementing this Protocol, Log can be buffered to an arbitrary location such as a text file or database.
public protocol LogBuffer: Sendable {
    func enqueue(_ event: [Payload]) async throws
    func dequeue(limit: Int?) async throws -> [Payload]
    func count() async throws -> Int
}

public extension LogBuffer {
    func load() async throws -> [Payload] {
        try await dequeue(limit: nil)
    }
}
