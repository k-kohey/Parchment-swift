//
//  File.swift
//  
//
//  Created by k-kohey on 2021/09/27.
//

import Foundation

public protocol LoggerComponent {
    func send(_: Loggable) -> Bool
}

public final class LoggerBundler {
    private let components: [LoggerComponent]
    private let buffer: TrackingEventBuffer
    private let loggingStorategy: BufferdEventLoggingStorategy
    
    public init(
        components: [LoggerComponent],
        buffer: TrackingEventBuffer = Buffer(),
        loggingStorategy: BufferdEventLoggingStorategy = RegularlyBufferdEventLoggingStorategy.default
    ) {
        self.components = components
        self.buffer = buffer
        self.loggingStorategy = loggingStorategy
    }
    
    public func send(_ event: Loggable, with policy: LoggingPolicy = .buffering) {
        if policy == .immediately {
            components.forEach {
                let isSucceeded = $0.send(event)
                if !isSucceeded {
                    buffer.save([.init(event: event, destination: "\(type(of: $0))")])
                }
            }
            return
        }
        
        components.forEach {
            buffer.save([.init(event: event, destination: "\(type(of: $0))")])
        }
    }
    
    public func startLogging() {
        loggingStorategy.schedule(with: buffer) { [weak self] events in
            events.forEach { event in
                self?.send(event, with: .immediately)
            }
        }
    }
}

public extension LoggerBundler {
    enum LoggingPolicy {
        case immediately
        case buffering
    }
}

public extension LoggerBundler {
    func send(_ event: ExpandableLoggingEvent, with policy: LoggingPolicy = .immediately) {
        send(event as Loggable, with: policy)
    }
}
