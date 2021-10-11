// 
//  File.swift
//  
//
//  Created by k-kohey on 2021/10/08.
//

import Foundation

public protocol Loggable {
    var eventName: String { get }
    var parameters: [String: String] { get }
}


public struct ExpandableLoggingEvent: Loggable {
    public let eventName: String
    public let parameters: [String : String]
    
    public init(eventName: String, parameters: [String : String]) {
        self.eventName = eventName
        self.parameters = parameters
    }
}

public extension ExpandableLoggingEvent {
    static func screenStart(name: String) -> ExpandableLoggingEvent {
        .init(eventName: "screenStart", parameters: ["name": name])
    }
}
