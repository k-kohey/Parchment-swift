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
    private let flushStorategy: BufferdEventFlushStorategy
    
    public var configMap: [LoggerComponentID: Configuration] = [:]
    
    public init(
        components: [LoggerComponent],
        buffer: TrackingEventBuffer,
        loggingStorategy: BufferdEventFlushStorategy = RegularlyBufferdEventFlushStorategy.default
    ) {
        self.components = components
        self.buffer = buffer
        self.flushStorategy = loggingStorategy
    }
    
    public func send(_ event: Loggable, with option: LoggingOption = .init()) {
        let loggers: [LoggerComponent] = {
            if let scope = option.scope {
                return components[scope]
            } else {
                return components
            }
        }()
        
        switch option.policy {
        case .immediately:
            loggers.forEach { logger in
                let isSucceeded = logger.send(event)
                let record = BufferRecord(destination: logger.id.value, event: event)
                let shouldBuffering = !isSucceeded && (configMap[logger.id]?.allowBuffering != .some(false))
                if shouldBuffering {
                    buffer.enqueue(record)
                } else if !isSucceeded {
                    console?.log("""
                    ⚠ The logger(id=\(logger.id.value)) failed to log an event \(event.eventName).
                    However, buffering is skiped because it is not allowed in the configuration.
                    """)
                }
            }
        case .bufferingFirst:
            loggers.forEach { logger in
                guard configMap[logger.id]?.allowBuffering != .some(false) else {
                    console?.log("""
                    ⚠ The logger(id=\(logger.id.value)) buffering has been skipped.
                    BufferingFirst policy has been selected in options, but the logger does not allow buffering.
                    """)
                    return
                }
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
        flushStorategy.schedule(with: buffer) { [weak self] records in
            records.forEach {
                self?.send(
                    $0.event,
                    with: .init(
                        policy: .immediately,
                        // いい感じにする
                        scope: .only([.init($0.destination)])
                    )
                )
            }
        }
    }
}

public extension LoggerBundler {
    enum LoggingPolicy {
        case immediately
        case bufferingFirst
    }
    
    enum LoggerScope {
        case only([LoggerComponentID])
        case exclude([LoggerComponentID])
    }
    
    struct LoggingOption {
        let policy: LoggingPolicy
        let scope: LoggerScope?
        
        public init(
            policy: LoggingPolicy = .bufferingFirst,
            scope: LoggerScope? = nil
        ) {
            self.policy = policy
            self.scope = scope
        }
    }
}

public extension LoggerBundler {
    struct Configuration {
        let allowBuffering: Bool
        
        public init(allowBuffering: Bool) {
            self.allowBuffering = allowBuffering
        }
    }
}

public extension LoggerBundler {
    func send(_ event: ExpandableLoggingEvent, with option: LoggingOption = .init()) {
        send(event as Loggable, with: option)
    }
}

private extension Sequence where Element == LoggerComponent {
    subscript(scope: LoggerBundler.LoggerScope) -> [Element] {
        switch scope {
        case .only(let loggerIDs):
            return filter { loggerIDs.contains($0.id) }
        case .exclude(let loggerIDs):
            return filter { !loggerIDs.contains($0.id) }
        }
    }
    
    subscript(id: LoggerComponentID) -> Element {
        first(where: { $0.id == id })!
    }
}
