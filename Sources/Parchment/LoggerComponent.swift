//
//  LoggerComponent.swift
//
//
//  Created by k-kohey on 2021/10/12.
//
import Foundation

public struct LoggerComponentID: Hashable, Sendable {
    let value: String

    public init(_ value: String) {
        self.value = value
    }
}

public protocol LoggerSendable: Sendable {
    var event: Loggable { get }
    var timestamp: Date { get }
}

public protocol LoggerComponent: Sendable {
    static var id: LoggerComponentID { get }
    func send(_: [any LoggerSendable]) async -> Bool
}

extension LoggerComponent {
    var id: LoggerComponentID {
        type(of: self).id
    }
}
