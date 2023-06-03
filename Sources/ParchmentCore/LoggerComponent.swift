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

/// Sending logs to your server or SDK such as Firebase.
public protocol LoggerComponent: Sendable {

    /// A unique identifier.
    /// This definition allows the user to specify an id when sending logs.
    static var id: LoggerComponentID { get }

    /// Sends an array of `LoggerSendable` objects asynchronously.
    ///
    /// - Parameter _: The array of `LoggerSendable` objects to send.
    /// - Returns: A boolean indicating whether the operation was successful.
    func send(_: [any LoggerSendable]) async -> Bool
}

extension LoggerComponent {
    var id: LoggerComponentID {
        type(of: self).id
    }
}
