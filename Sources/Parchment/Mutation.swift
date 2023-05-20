//
//  Mutation.swift
//
//
//  Created by k-kohey on 2021/12/09.
//

import Foundation

public struct AnyLoggable: Loggable {
    public var eventName: String
    public var parameters: [String : Sendable]

    public let base: (any Loggable)?

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
}

typealias Transform = @Sendable (Loggable, LoggerComponentID) -> AnyLoggable

public protocol Mutation: Sendable {
    func transform(_: any Loggable, id: LoggerComponentID) -> AnyLoggable
}

private extension Mutation {
    var _transform: Transform {
        {
            self.transform($0, id: $1)
        }
    }
}

extension Sequence where Element == Mutation {
    func composed() -> Transform {
        return map { $0._transform }.composed()
    }
}

extension Sequence where Element == Transform {
    func composed() -> Transform {
        let base: Transform = { log, _ in AnyLoggable(log) }
        return reduce(base) { partialResult, transform in
            {
                transform(partialResult($0, $1), $1)
            }
        }
    }
}
