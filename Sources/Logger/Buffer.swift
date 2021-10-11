// 
//  File.swift
//  
//
//  Created by k-kohey on 2021/10/08.
//

import Foundation

public struct BufferRecord {
    let event: Loggable
    let destination: String
}

public protocol TrackingEventBuffer {
    func save(_ :[BufferRecord])
    func load() -> [Loggable]
    func count() -> Int
}

public struct Buffer: TrackingEventBuffer {
    public func save(_ :[BufferRecord]) {}
    public func load() -> [Loggable] { [] }
    public func count() -> Int { 0 }
    
    public init() {}
}
