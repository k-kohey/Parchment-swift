//
//  BufferRecord.swift
//
//
//  Created by k-kohey on 2021/10/08.
//

import Foundation

public struct BufferRecord: Loggable, LoggerSendable, Equatable {
    public let id: String
    public let destination: String
    public let eventName: String
    public let parameters: [String: Any]
    public let timestamp: Date

    public init(id: String = UUID().uuidString, destination: String, event: Loggable, timestamp: Date) {
        self.id = id
        self.destination = destination
        eventName = event.eventName
        parameters = event.parameters
        self.timestamp = timestamp
    }

    public init(
        id: String = UUID().uuidString,
        destination: String,
        eventName: String,
        parameters: [String: Any],
        timestamp: Date
    ) {
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

public extension BufferRecord {
    var event: Loggable {
        TrackingEvent(eventName: eventName, parameters: parameters)
    }
}
