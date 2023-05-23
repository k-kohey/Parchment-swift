//
//  File.swift
//  
//
//  Created by Kohei Kawaguchi on 2023/05/23.
//

import Foundation

@globalActor
final actor AnyLoggableActor {
    static var shared: AnyLoggableActor = .init()
}

@AnyLoggableActor
private var findCache: [UUID: [String: Bool]] = [:]

public struct AnyLoggable: Loggable {
    public var eventName: String
    public var parameters: [String : Sendable]

    public let base: (any Loggable)?
    private let id: UUID = .init()

    public init(_ base: any Loggable) {
        self.base = base
        self.eventName = base.eventName
        self.parameters = base.parameters
    }

    public init(
        eventName: String, parameters: [String : Sendable]
    ) {
        self.base = nil
        self.eventName = eventName
        self.parameters = parameters
    }

    @AnyLoggableActor
    public func isBased<T: Loggable>(_ type: T.Type) -> Bool {
        if findCache[id]?["\(T.self)"] == true {
            return true
        }
        let result = find(T.self, from: self)
        if findCache[id] == nil {
            findCache[id] = [:]
        }
        findCache[id]?["\(T.self)"] = result
        return result
    }

    private func find<T: Loggable>(
        _ type: T.Type, from anyLoggable: AnyLoggable
    ) -> Bool {
        if let base = anyLoggable.base, base is T {
            return true
        } else if let innerAnyLoggable = anyLoggable.base as? AnyLoggable {
            return find(T.self, from: innerAnyLoggable)
        } else {
            return false
        }
    }
}
