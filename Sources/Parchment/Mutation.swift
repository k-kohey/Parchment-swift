//
//  Mutation.swift
//
//
//  Created by k-kohey on 2021/12/09.
//

import Foundation

typealias Transform = @Sendable @AnyLoggableActor (Loggable, LoggerComponentID) -> AnyLoggable

/// Transform a given log into another log.
///
/// If there are parameters that should be inserted for all logs, such as UserID and Timestamp,
/// `Mutation` can be used to implement this.
///
/// The example below illustrates how to use `Mutation` to insert a UserID into the parameters of a log.
/// By implementing it in this way, it saves the effort of inserting this into each individual log.
///
///     struct UserIDMutation: Mutation {
///         let userID: ID
///
///         func transform(_ e: Loggable, id: LoggerComponentID) -> AnyLoggable {
///             var e = AnyLoggable(e)
///             e.parameters["userID"] = userID
///             return e
///         }
///     }
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
