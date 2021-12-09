//
//  File.swift
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

#if canImport(UIKit)

import UIKit

public struct DeviceDataMutation: Mutation {
    private let deviceParams = [
        "Model": UIDevice.current.name,
        "OS": UIDevice.current.systemName,
        "OS Version": UIDevice.current.systemVersion
    ]
    
    public func transform(_ event: Loggable, id: LoggerComponentID) -> Loggable {
        let new: [PartialKeyPath<Loggable>: Any] = [
            \.eventName: event.eventName,
            \.parameters: event.parameters.merging(deviceParams) { left, _ in left }
        ]
        return new
    }
}

#endif
