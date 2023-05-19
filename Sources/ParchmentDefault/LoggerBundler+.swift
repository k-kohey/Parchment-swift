//
//  LoggerBundler+.swift
//
//
//  Created by k-kohey on 2021/12/29.
//

import Parchment

public extension LoggerBundler {
    static func make(
        components: [any LoggerComponent],
        buffer: some LogBuffer = try! SQLiteBuffer(),
        bufferFlowController: some BufferFlowController = DefaultBufferFlowController(pollingInterval: 60)
    ) -> LoggerBundler {
        Self(components: components, buffer: buffer, bufferFlowController: bufferFlowController)
    }
}
