// 
//  File.swift
//  
//
//  Created by k-kohey on 2021/10/08.
//

import Foundation

public protocol Loggable {
    var eventName: String { get }
    var parameters: [String: Any] { get }
}

public struct TrackingEvent: Loggable {
    public let eventName: String
    public let parameters: [String : Any]
    
    public init(eventName: String, parameters: [String : Any]) {
        self.eventName = eventName
        self.parameters = parameters
    }
}

extension Dictionary: Loggable where Key == PartialKeyPath<Loggable> {
    public var eventName: String {
        self[\.eventName] as? String ?? ""
    }
    
    public var parameters: [String : Any] {
        self[\.parameters] as? [String : Any] ?? [:]
    }
}
