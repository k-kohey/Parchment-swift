//
//  osLogger.swift
//  
//
//  Created by Kohei Kawaguchi on 2023/05/20.
//

import os
import Foundation

@_spi(ParchmentCore) public let osLogger = Logger(subsystem: "com.k-kohey.parchment", category: "parchment")

public extension LoggerComponentID {
    static var debug: LoggerComponentID {
        .init("debug")
    }
}

public struct DebugLogger: LoggerComponent {
    public static let id: LoggerComponentID = .debug

    public init() {}

    public func send(_ log: [LoggerSendable]) async -> Bool {
        osLogger.debug(
            "🚀 Send \(log.count) events\n\(log.reduce("", { $0 + "\($1)\n" }))"
        )
        return true
    }
}
