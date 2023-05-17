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

// TODO: Delete
public typealias TrackingEvent = AnyLoggable
