//
//  LoggerBundler.swift
//
//
//  Created by k-kohey on 2021/09/27.
//
import Foundation

public final actor LoggerBundler {
    private var components: [any LoggerComponent]
    private let buffer: TrackingEventBuffer
    private let flushStrategy: BufferedEventFlushScheduler

    public var configMap: [LoggerComponentID: Configuration] = [:]
    public var mutations: [any Mutation] = []

    private var loggingTask: Task<Void, Never>?

    public init(
        components: [any LoggerComponent],
        buffer: some TrackingEventBuffer,
        loggingStrategy: some BufferedEventFlushScheduler
    ) {
        self.components = components
        self.buffer = buffer
        flushStrategy = loggingStrategy
    }

    public func add(component: LoggerComponent) {
        components.append(component)
    }

    public func send(_ event: some Loggable, with option: LoggingOption = .init()) async {
        assert(!components.isEmpty, "Should set the any logger")
        let loggers: [any LoggerComponent] = {
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
                timestamp: .init()
            )
            await dispatch([record], for: logger, with: option)
        }
    }

    private func dispatch(
        _ records: [BufferRecord],
        for logger: some LoggerComponent,
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
            await buffer.save(records)
        }
    }

    private func upload(_ records: [BufferRecord], with logger: any LoggerComponent) async {
        let isSucceeded = await logger.send(records)
        let shouldBuffering = !isSucceeded && (configMap[logger.id]?.allowBuffering != .some(false))
        if shouldBuffering {
            await buffer.save(records)
        } else if !isSucceeded {
//            console()?.log("""
//            ⚠ The logger(id=\(logger.id.value)) failed to log an event.
//            However, buffering is skiped because it is not allowed in the configuration.
//            """)
        }
    }

    @discardableResult
    public func startLogging() -> Task<Void, Error> {
        Task {
            for try await records in await flushStrategy.schedule(with: buffer) {
                await self.bloadcast(records)
            }
        }
    }

    private func bloadcast(_ records: [BufferRecord]) async {
        let recordEachLogger = Dictionary(grouping: records) { record in
            record.destination
        }

        for (destination, records) in recordEachLogger {
            await upload(records, with: components[.init(destination)])
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
    func send(event: TrackingEvent, with option: LoggingOption = .init()) async {
        await send(event, with: option)
    }

    func send(event: [PartialKeyPath<Loggable>: Sendable], with option: LoggingOption = .init()) async {
        await send(event, with: option)
    }
}

private extension Sequence where Element == LoggerComponent {
    subscript(scope: LoggerBundler.LoggerScope) -> [any LoggerComponent] {
        switch scope {
        case let .only(loggerIDs):
            return filter { loggerIDs.contains($0.id) }
        case let .exclude(loggerIDs):
            return filter { !loggerIDs.contains($0.id) }
        }
    }

    subscript(id: LoggerComponentID) -> any LoggerComponent {
        first(where: { $0.id == id })!
    }
}
