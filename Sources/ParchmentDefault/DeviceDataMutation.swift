//
//  DeviceDataMutation.swift
//
//
//  Created by k-kohey on 2021/12/29.
//

#if canImport(UIKit)

    import Parchment
    import UIKit

    public struct DeviceDataMutation: Mutation {
        private let deviceParams = [
            "Model": UIDevice.current.name,
            "OS": UIDevice.current.systemName,
            "OS Version": UIDevice.current.systemVersion
        ]

        public func transform(_ event: Loggable, id _: LoggerComponentID) -> Loggable {
            let log: LoggableDictonary = [
                \.eventName: event.eventName,
                \.parameters: event.parameters.merging(deviceParams) { left, _ in left }
            ]
            return log
        }
    }

#endif
