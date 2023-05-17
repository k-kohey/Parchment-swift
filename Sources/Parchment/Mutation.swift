//
//  Mutation.swift
//
//
//  Created by k-kohey on 2021/12/09.
//

import Foundation

typealias Transform = (Loggable, LoggerComponentID) -> any Loggable

public protocol Mutation: Sendable {
    func transform(_: any Loggable, id: LoggerComponentID) -> any Loggable
}

extension Sequence where Element == Mutation {
    func composed() -> Transform {
        map { $0.transform }.composed()
    }
}

extension Sequence where Element == Transform {
    func composed() -> Transform {
        reduce({ log, _ in log }) { partialResult, transform in
            {
                transform(partialResult($0, $1), $1)
            }
        }
    }
}
