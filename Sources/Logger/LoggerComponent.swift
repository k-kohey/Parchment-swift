// 
//  File.swift
//  
//
//  Created by k-kohey on 2021/10/12.
//

import Foundation

public struct LoggerComponentID: Hashable {
    let value: String
    
    public init(_ value: String) {
        self.value = value
    }
}

public protocol LoggerComponent {
    static var id: LoggerComponentID { get }
    func send(_: Loggable) -> Bool
}

extension LoggerComponent {
    var id: LoggerComponentID {
        type(of: self).id
    }
}
