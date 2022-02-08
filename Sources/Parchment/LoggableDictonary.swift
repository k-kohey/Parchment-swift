//
//  LoggableDictonary.swift
//  
//
//  Created by k-kohey on 2022/02/08.
//

import Foundation

/// Experimental API

public typealias LoggableDictonary = Dictionary<PartialKeyPath<Loggable>, Any>

extension LoggableDictonary: Loggable {
    public var eventName: String {
        self[\.eventName] as? String ?? ""
    }
    
    public var parameters: [String : Any] {
        get {
            self[\.parameters] as? [String : Any] ?? [:]
        }
    }
}
