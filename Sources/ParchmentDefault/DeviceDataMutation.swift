//
//  DeviceDataMutation.swift
//
//
//  Created by k-kohey on 2021/12/29.
//

import Parchment
import UIKit

public struct DeviceDataMutation: Mutation {
    private let deviceParams: [String: Sendable]

    @MainActor
    public init(device: UIDevice) {
        deviceParams = [
            "Model": device.name,
            "OS": device.systemName,
            "OS Version": device.systemVersion
        ]
    }

    public func transform(_ event: any Loggable, id _: LoggerComponentID) -> AnyLoggable {
        var event = AnyLoggable(event)
        event.parameters = event.parameters.merging(deviceParams) { left, _ in left }
        return event
    }
}
