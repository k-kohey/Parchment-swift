//
//  LoggerBundler.swift
//
//
//  Created by k-kohey on 2021/09/27.
//
import Foundation

public final actor LoggerBundler {
    private var components: [any LoggerComponent]
    private let buffer: LogBuffer
    private let bufferFlowController: BufferFlowController

    public var configMap: [LoggerComponentID: Configuration] = [:]
    private(set) var transform: Transform

    private var loggingTask: Task<Void, Never>?

    public init(
        components: [any LoggerComponent],
        buffer: some LogBuffer,
        bufferFlowController: some BufferFlowController,
        mutations: [Mutation] = []
    ) {
        self.components = components
        self.buffer = buffer
        self.bufferFlowController = bufferFlowController
        transform = mutations.composed()
    }

    public func add(component: LoggerComponent) {
        components.append(component)
    }

    public func add(mutations: [Mutation]) {
        transform = ([transform, mutations.composed()]).composed()
    }

    /// Sends a Log to the retained LoggerComponents.
    /// A LoggerComponent should be added before this function is called.
    /// - Parameters:
    ///   - event: Log to be sent
    ///   - option: Option the method and target of sending.
    public nonisolated func send(_ event: some Loggable, with option: LoggingOption = .init()) async {
        func loggers() async -> [any LoggerComponent] {
            if let scope = option.scope {
                return await components[scope]
            } else {
                return await components
            }
        }

        await withTaskGroup(of: Void.self) { group in
            for logger in await loggers() {
                let payload = await Payload(
                    destination: logger.id.value,
                    event: transform(event, logger.id),
                    timestamp: .init()
                )

                group.addTask {
                    switch option.policy {
                    case .immediately:
                        await self.upload([payload], with: logger)
                    case .bufferingFirst:
                        do {
                            try await self.bufferFlowController.input(
                                [payload], with: self.buffer
                            )
                        } catch {
                            osLogger.error("The following error occurred when saving Log to Buffer\n\(error)")
                        }
                    }
                }
            }
        }
    }

    private func upload(_ payloads: [Payload], with logger: any LoggerComponent) async {
        let isSucceeded = await logger.send(payloads)
        let shouldBuffering = !isSucceeded
        if shouldBuffering {
            do {
                try await self.bufferFlowController.input(
                    payloads, with: self.buffer
                )
            } catch {
                osLogger.error("The following error occurred when saving Log to Buffer\n\(error)")
            }
        }
    }

    @discardableResult
    public func startLogging() -> Task<Void, Error> {
        Task {
            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    for try await payloads in await bufferFlowController.output(with: buffer) {
                        group.addTask {
                            let payloadEachLogger = Dictionary(grouping: payloads) {
                                $0.destination
                            }
                            for (destination, payloads) in payloadEachLogger {
                                await self.upload(payloads, with: self.components[.init(destination)])
                            }
                        }
                    }
                }
            } catch {
                osLogger.error("The following error occurred when polling Log to Buffer\n\(error)")
                throw error
            }
        }
    }
}

public extension LoggerBundler {
    enum LoggingPolicy: Sendable {
        case immediately
        case bufferingFirst
    }

    enum LoggerScope: Sendable {
        case only([LoggerComponentID])
        case exclude([LoggerComponentID])
    }

    struct LoggingOption: Sendable {
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
