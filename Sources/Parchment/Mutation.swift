//
//  Mutation.swift
//
//
//  Created by k-kohey on 2021/12/09.
//

import Foundation

public protocol Mutation {
    func transform(_: any Loggable, id: LoggerComponentID) -> any Loggable
}

extension Sequence where Element == Mutation {
    func transform(_ events: any Loggable, id: LoggerComponentID) -> any Loggable {
        reduce(events) { partialResult, mutation in
            mutation.transform(partialResult, id: id)
        }
    }
}
