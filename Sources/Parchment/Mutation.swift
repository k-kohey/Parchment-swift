//
//  Mutation.swift
//
//
//  Created by k-kohey on 2021/12/09.
//

import Foundation

typealias Transform = @Sendable @AnyLoggableActor (Loggable, LoggerComponentID) -> AnyLoggable

public protocol Mutation: Sendable {
    @AnyLoggableActor 
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
