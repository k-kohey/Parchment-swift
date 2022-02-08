//
//  Mutation.swift
//  
//
//  Created by k-kohey on 2021/12/09.
//

import Foundation

public protocol Mutation {
    func transform(_: Loggable, id: LoggerComponentID) -> Loggable
}

extension Sequence where Element == Mutation {
    func transform(_ events: Loggable, id: LoggerComponentID) -> Loggable {
        reduce(events) { partialResult, mutation in
            mutation.transform(partialResult, id: id)
        }
    }
}
