//
//  File.swift
//  
//
//  Created by k-kohey on 2021/09/27.
//

import Foundation

public final class LoggerBundler {
    private let components: [LoggerComponent]
    private let buffer: TrackingEventBuffer
    private let loggingStorategy: BufferdEventLoggingStorategy
    
    public init(
        components: [LoggerComponent],
        buffer: TrackingEventBuffer,
        loggingStorategy: BufferdEventLoggingStorategy = RegularlyBufferdEventLoggingStorategy.default
    ) {
        self.components = components
        self.buffer = buffer
        self.loggingStorategy = loggingStorategy
    }
    
    public func send(_ event: Loggable, with policy: LoggingPolicy = .bufferingFirst) {
        if policy == .immediately {
            components.forEach { logger in
                let isSucceeded = logger.send(event)
                let record = BufferRecord(destination: logger.id.value, event: event)
                if !isSucceeded {
                    buffer.enqueue(record)
                }
            }
        } else {
            components.forEach { logger in
                buffer.enqueue(
                    .init(
                        destination: logger.id.value,
                        event: event
                    )
                )
            }
        }
    }
    
    public func startLogging() {
        loggingStorategy.schedule(with: buffer) { [weak self] records in
            records.forEach {
                self?.send($0.event)
            }
        }
    }
}

public extension LoggerBundler {
    enum LoggingPolicy {
        case immediately
        case bufferingFirst
    }
    
//    enum LoggingOption {
//        case policy(LoggingPolicy)
//        case exclude([LoggerComponentID])
//    }
}

public extension LoggerBundler {
    func send(_ event: ExpandableLoggingEvent, with policy: LoggingPolicy = .immediately) {
        send(event as Loggable, with: policy)
    }
}
