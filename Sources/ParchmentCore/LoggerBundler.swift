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

    private var mutations: [any Mutation] = []

    public init(
        components: [any LoggerComponent],
        buffer: some LogBuffer,
        bufferFlowController: some BufferFlowController,
        mutations: [any Mutation] = []
    ) {
        self.components = components
        self.buffer = buffer
        self.bufferFlowController = bufferFlowController
        self.mutations = mutations
    }

    public func add(component: LoggerComponent) {
        components.append(component)
    }

    public func add(mutations: [Mutation]) {
        self.mutations += mutations
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
                    event: mutations.transform(event, id: logger.id),
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

    /// Dequeue Log from Buffer and start sending Log to LoggerComponent.
    /// The number and timing of Log dequeues are determined by BufferFlowController.
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
    /// Log sending timing
    enum LoggingPolicy: Sendable {
        /// requires the log o be sent to LoggerComponent immediately without storing it in the buffer.
        /// When this is specified, logs can be sent ignoring the waiting order of buffer.
        case immediately
        case bufferingFirst
    }

    /// Scope of sending logs
    ///
    /// If specified as follows, Logs are sent only to the LoggerComponent
    /// whose LoggerComponentID is defined as myLogger.
    ///
    ///      extension LoggerComponentID {
    ///         static var myLogger: LoggerComponentID = { .init("myLogger") }
    ///      }
    ///
    ///      await logger.send(
    ///         event,
    ///         with: .init(scope: .only(.myLogger))
    ///      )
    enum LoggerScope: Sendable {
        case only([LoggerComponentID])
        case exclude([LoggerComponentID])
    }

    ///  Settings on how logs are sent
    ///  The default settings sends logs to all LoggerComponents after first storing them in a buffer
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
