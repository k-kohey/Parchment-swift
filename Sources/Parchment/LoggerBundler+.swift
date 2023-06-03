//
//  LoggerBundler+.swift
//
//
//  Created by k-kohey on 2021/12/29.
//

private let standardInstance = LoggerBundler.make(components: [])

public extension LoggerBundler {
    static func make(
        components: [any LoggerComponent],
        buffer: some LogBuffer = try! SQLiteBuffer(),
        bufferFlowController: some BufferFlowController = DefaultBufferFlowController(pollingInterval: 60),
        mutations: [Mutation] = []
    ) -> LoggerBundler {
        Self(
            components: components,
            buffer: buffer,
            bufferFlowController: bufferFlowController,
            mutations: mutations
        )
    }

    /// This is a singleton instance.
    /// Properties such as LoggerComponent and Mutation are empty, so set them as necessary.
    static var `standard`: LoggerBundler {
        standardInstance
    }
}
