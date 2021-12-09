//
//  File.swift
//  
//
//  Created by k-kohey on 2021/12/09.
//

import Foundation

public protocol Mutation {
    func transform(_: [LoggerSendable], id: LoggerComponentID) -> [LoggerSendable]
}

extension Sequence where Element == Mutation {
    func transform(_ events: [LoggerSendable], id: LoggerComponentID) -> [LoggerSendable] {
        reduce(events) { partialResult, mutation in
            mutation.transform(partialResult, id: id)
        }
    }
}
