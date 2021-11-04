//
//  File.swift
//  
//
//  Created by k-kohey on 2021/09/27.
//

import Foundation

struct DateProvider {
    static var mock: Date?
    
    static func current() -> Date {
        Self.mock ?? .init()
    }
}

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
        
        loggers.forEach { logger in
            let record = BufferRecord(
                destination: logger.id.value,
                event: event,
                timestamp: DateProvider.current()
            )
            send(record, using: logger, with: option)
        }
    }
    
    private func send(_ record: BufferRecord, using logger: LoggerComponent, with option: LoggingOption = .init()) {
        switch option.policy {
        case .immediately:
            let isSucceeded = logger.send(record.event)
            let shouldBuffering = !isSucceeded && (configMap[logger.id]?.allowBuffering != .some(false))
            if shouldBuffering {
                buffer.enqueue(record)
            } else if !isSucceeded {
                console?.log("""
                ⚠ The logger(id=\(logger.id.value)) failed to log an event \(record.event.eventName).
                However, buffering is skiped because it is not allowed in the configuration.
                """)
            }
        case .bufferingFirst:
            guard configMap[logger.id]?.allowBuffering != .some(false) else {
                console?.log("""
                ⚠ The logger(id=\(logger.id.value)) buffering has been skipped.
                BufferingFirst policy has been selected in options, but the logger does not allow buffering.
                """)
                return
            }
            buffer.enqueue(record)
        }
    }
    
    public func startLogging() {
        flushStorategy.schedule(with: buffer) { [weak self] records in
            guard let self = self else {
                assertionFailure("""
                LoggerBundler instance should been retainted by any objects for logging.
                Logging cannot be performed in this state.
                """)
                return
            }
            
            records.forEach {
                self.send(
                    $0,
                    using: self.components[.init($0.destination)]
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
            policy: LoggingPolicy = .immediately,
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

private extension BufferRecord {
    struct Event: Loggable {
        public let eventName: String
        public let parameters: [String: Any]
    }
    
    var event: Event {
        .init(eventName: eventName, parameters: parameters)
    }
}
