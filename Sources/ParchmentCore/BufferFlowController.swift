//
//  BufferedEventFlushScheduler.swift
//
//
//  Created by k-kohey on 2021/10/08.
//
import Foundation

/// Helps in managing the flow of logs between LoggerBundler and LogBuffer.
/// It provides functions for input and output operations on logs in a LogBuffer.
public protocol BufferFlowController: Sendable {
    /// Saves the given Payload to LogBuffer.
    ///
    /// Depending on the LogBuffer implementation, it may be better to store a certain number of payloads at once.
    /// In such cases, this function can delay saving until a certain number of payloads are stored.
    ///
    /// - Parameters:
    ///   - _: The array of Payload objects to be saved.
    ///   - buffer: The LogBuffer where the Payload objects will be saved.
    func input<T: LogBuffer>(_: [Payload], with buffer: T) async throws

    /// Asynchronously read Payload from LogBuffer based on certain conditions
    ///
    /// Read an arbitrary number of Logs from Buffer at an arbitrary timing
    /// using polling, observer patterns, etc., and send them to AsyncStream.
    ///
    /// Note that if no events flow into the return value AsyncStream,
    /// the LoggerBundler will not be able to retrieve the buffered log from the LogBuffer.
    ///
    /// - Parameter _: The LogBuffer from which the Payload objects will be loaded.
    /// - Returns: Stream for LoggerBundler to subscribe and send Log to LoggerComponent
    func output<T: LogBuffer>(with: T) async -> AsyncThrowingStream<[Payload], Error>
}
