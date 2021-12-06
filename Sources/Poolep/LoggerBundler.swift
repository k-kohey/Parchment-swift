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
    private let buffer: TrackingEventBufferAdapter
    private let flushStorategy: BufferdEventFlushStorategy
    
    public var configMap: [LoggerComponentID: Configuration] = [:]
    
    public init(
        components: [LoggerComponent],
        buffer: TrackingEventBuffer = try! SQLiteBuffer(),
        loggingStorategy: BufferdEventFlushStorategy = RegularlyBufferdEventFlushStorategy.default
    ) {
        self.components = components
        self.buffer = .init(buffer)
        self.flushStorategy = loggingStorategy
    }
    
    public func send(_ event: Loggable, with option: LoggingOption = .init()) async {
        let loggers: [LoggerComponent] = {
            if let scope = option.scope {
                return components[scope]
            } else {
                return components
            }
        }()
        
        for logger in loggers {
            let record = BufferRecord(
                destination: logger.id.value,
                event: event,
                timestamp: DateProvider.current()
            )
            await send(record, using: logger, with: option)
        }
    }
    
    private func send(_ record: BufferRecord, using logger: LoggerComponent, with option: LoggingOption = .init()) async {
        switch option.policy {
        case .immediately:
            let isSucceeded = await logger.send(record.event)
            let shouldBuffering = !isSucceeded && (configMap[logger.id]?.allowBuffering != .some(false))
            if shouldBuffering {
                await buffer.enqueue(record)
            } else if !isSucceeded {
                print("""
                ⚠ The logger(id=\(logger.id.value)) failed to log an event \(record.event.eventName).
                However, buffering is skiped because it is not allowed in the configuration.
                """)
            }
        case .bufferingFirst:
            guard configMap[logger.id]?.allowBuffering != .some(false) else {
                print("""
                ⚠ The logger(id=\(logger.id.value)) buffering has been skipped.
                BufferingFirst policy has been selected in options, but the logger does not allow buffering.
                """)
                return
            }
            await buffer.enqueue(record)
        }
    }
    
    public func startLogging() {
        Task.detached { [weak self] in
            guard let self = self else {
                assertionFailure("LoggerBundler instance should been retained by any object due to log events definitely")
                return
            }
            do {
                for try await record in self.flushStorategy.schedule(with: self.buffer) {
                    await self.send(
                        record,
                        using: self.components[.init(record.destination)]
                    )
                }
            } catch {
                print("error: \(error.localizedDescription)")
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
    func send(_ event: ExpandableLoggingEvent, with option: LoggingOption = .init()) async {
        await send(event as Loggable, with: option)
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
