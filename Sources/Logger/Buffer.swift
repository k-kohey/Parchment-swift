// 
//  File.swift
//  
//
//  Created by k-kohey on 2021/10/08.
//

import Foundation

public struct BufferRecord: Loggable, Equatable {
    public let id: String
    public let destination: String
    public let eventName: String
    public let parameters: [String: Any]
    let timestamp: Date
    
    init(id: String = UUID().uuidString, destination: String, event: Loggable, timestamp: Date) {
        self.id = id
        self.destination = destination
        self.eventName = event.eventName
        self.parameters = event.parameters
        self.timestamp = timestamp
    }
    
    internal init(id: String = UUID().uuidString, destination: String, eventName: String, parameters: [String : Any], timestamp: Date) {
        self.id = id
        self.destination = destination
        self.eventName = eventName
        self.parameters = parameters
        self.timestamp = timestamp
    }
    
    public static func == (lhs: BufferRecord, rhs: BufferRecord) -> Bool {
        lhs.id == rhs.id
            && lhs.destination == rhs.destination
            && lhs.eventName == rhs.eventName
            && (lhs.parameters as NSDictionary).isEqual(to: rhs.parameters)
            && lhs.timestamp == rhs.timestamp
    }
}

public protocol TrackingEventBuffer {
    func enqueue(_ e: BufferRecord)
    func dequeue() -> BufferRecord?
    func dequeue(limit: Int64) -> [BufferRecord]
    func count() -> Int
}

final actor TrackingEventBufferAdapter {
    private let buffer: TrackingEventBuffer
    
    init(_ buffer: TrackingEventBuffer) {
        self.buffer = buffer
    }
    
    func enqueue(_ e: BufferRecord) {
        buffer.enqueue(e)
    }
    
    func dequeue() -> BufferRecord? {
        buffer.dequeue()
    }
    
    func dequeue(limit: Int64) -> [BufferRecord] {
        buffer.dequeue(limit: limit)
    }
    
    func count() -> Int {
        buffer.count()
    }
}
