//
//  Loggable.swift
//
//
//  Created by k-kohey on 2021/10/08.
//

import Foundation

public protocol Loggable: Sendable {
    var eventName: String { get }
    var parameters: [String: Sendable] { get }
}

public struct TrackingEvent: Loggable {
    public let eventName: String
    public let parameters: [String: Sendable]

    public init(eventName: String, parameters: [String: Sendable]) {
        self.eventName = eventName
        self.parameters = parameters
    }
}
