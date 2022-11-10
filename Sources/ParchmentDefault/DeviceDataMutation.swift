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
        private let deviceParams: [String: Any]

        @MainActor
        public init(device: UIDevice) {
            deviceParams = [
                "Model": device.name,
                "OS": device.systemName,
                "OS Version": device.systemVersion
            ]
        }

        public func transform(_ event: any Loggable, id _: LoggerComponentID) -> any Loggable {
            let log: LoggableDictonary = [
                \.eventName: event.eventName,
                \.parameters: event.parameters.merging(deviceParams) { left, _ in left }
            ]
            return log
        }
    }

#endif
