//
//  LoggableDictonary.swift
//
//
//  Created by k-kohey on 2022/02/08.
//

import Foundation

/// Experimental API

public typealias LoggableDictonary = [PartialKeyPath<Loggable>: Sendable]

extension PartialKeyPath<Loggable>: @unchecked Sendable {}

extension LoggableDictonary: Loggable {
    public var eventName: String {
        self[\.eventName] as? String ?? ""
    }

    public var parameters: [String: Sendable] {
        self[\.parameters] as? [String: Sendable] ?? [:]
    }
}
