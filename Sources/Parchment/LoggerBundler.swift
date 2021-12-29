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
    private let flushStorategy: BufferdEventFlushScheduler
    
    public var configMap: [LoggerComponentID: Configuration] = [:]
    public var mutations: [Mutation] = []
    
    public init(
        components: [LoggerComponent],
        buffer: TrackingEventBuffer,
        loggingStorategy: BufferdEventFlushScheduler
    ) {
        assert(!components.isEmpty, "Should set the any logger with initializer")
        
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
                event: mutations.transform(event, id: logger.id),
                timestamp: DateProvider.current()
            )
            await dispatch([record], for: logger, with: option)
        }
    }
    
    private func dispatch(
        _ records: [BufferRecord],
        for logger: LoggerComponent,
        with option: LoggingOption
    ) async {
        switch option.policy {
        case .immediately:
            await upload(records, with: logger)
        case .bufferingFirst:
            guard configMap[logger.id]?.allowBuffering != .some(false) else {
//                console()?.log("""
//                ⚠ The logger(id=\(logger.id.value)) buffering has been skipped.
//                BufferingFirst policy has been selected in options, but the logger does not allow buffering.
//                """)
                return
            }
            await buffer.enqueue(records)
        }
    }
    
    private func upload(_ records: [BufferRecord], with logger: LoggerComponent) async {
        let isSucceeded = await logger.send(records)
        let shouldBuffering = !isSucceeded && (configMap[logger.id]?.allowBuffering != .some(false))
        if shouldBuffering {
            await buffer.enqueue(records)
        } else if !isSucceeded {
//            console()?.log("""
//            ⚠ The logger(id=\(logger.id.value)) failed to log an event.
//            However, buffering is skiped because it is not allowed in the configuration.
//            """)
        }
    }
    
    public func startLogging() {
        Task { [weak self] in
            guard let self = self else {
                assertionIfDebugMode("LoggerBundler instance should been retained by any object due to log events definitely")
                return
            }
            do {
                for try await records in self.flushStorategy.schedule(with: self.buffer) {
                    await self.bloadcast(records)
                }
            } catch {
//                console()?.log("\(error.localizedDescription)")
            }
        }
    }
    
    private func bloadcast(_ records: [BufferRecord]) async {
        let recordEachLogger = Dictionary(grouping: records) { record in
            record.destination
        }
        
        for (destination, records) in recordEachLogger {
            await upload(records, with: self.components[.init(destination)])
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
    func send(_ event: TrackingEvent, with option: LoggingOption = .init()) async {
        await send(event as Loggable, with: option)
    }
    
    func send(_ event: [PartialKeyPath<Loggable>: Any], with option: LoggingOption = .init()) async {
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
