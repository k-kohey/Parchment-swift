// 
//  File.swift
//  
//
//  Created by k-kohey on 2021/10/08.
//

import Foundation

public struct BufferRecord {
    public let id = UUID().uuidString
    public let destination: String
    public let event: Loggable
}

public protocol TrackingEventBuffer {
    func enqueue(_ e: BufferRecord)
    func dequeue() -> BufferRecord?
    func dequeue(limit: Int) -> [BufferRecord]
    func count() -> Int
}
