//
//  File.swift
//  
//
//  Created by k-kohey on 2021/12/29.
//

import Parchment

private var defaultInstance: LoggerBundler!

public extension LoggerBundler {
    static func make(
        components: [LoggerComponent],
        buffer: TrackingEventBuffer = try! SQLiteBuffer(),
        loggingStorategy: BufferdEventFlushScheduler = RegularlyPollingScheduler.default
    ) -> LoggerBundler {
        Self(components: components, buffer: buffer, loggingStorategy: loggingStorategy)
    }
}
