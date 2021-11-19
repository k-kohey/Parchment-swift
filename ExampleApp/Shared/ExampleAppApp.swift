//
//  ExampleAppApp.swift
//  Shared
//
//  Created by k-kohey on 2021/11/20.
//

import SwiftUI
import Poolep

@main
struct ExampleAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    let logger = makeLogger()
                    logger.startLogging()
                    logger.send(.impletion)
                }
        }
    }
}

extension LoggerComponentID {
    static let hoge: Self = .init("hoge")
}

struct HogelLogger: LoggerComponent {
    static var id: LoggerComponentID = .hoge
    
    func send(_ e: Loggable) -> Bool {
        // do logging
        print("🚀 send to mixpanel:\n   =>\(e)")
        return true
    }
    
    func setCustomProperty(_ : [String: String]) {
        // do anything
    }
}

extension ExpandableLoggingEvent {
    static let impletion = ExpandableLoggingEvent(eventName: "impletion", parameters: [:])
}


final class EventQueue: TrackingEventBuffer {
    private var records: [BufferRecord] = []
    
    func enqueue(_ e: BufferRecord) {
        records.append(e)
    }
    
    func dequeue() -> BufferRecord? {
        defer {
            if !records.isEmpty {
                records.removeFirst()
            }
        }
        return records.first
    }
    
    func dequeue(limit: Int64) -> [BufferRecord] {
        (0..<min(Int(limit), records.count)).reduce([]) { result, _ in
            result + [dequeue()].compactMap { $0 }
        }
    }
    
    func count() -> Int {
        records.count
    }
}

func makeLogger() -> LoggerBundler {
    Configuration.shouldPrintDebugLog = true
    
    // イベントをプールするデータベースを宣言
    let buffer = EventQueue()

    // どのようなロジックでプールしたイベントをバックエンドに送信するかを宣言
    let storategy = RegularlyBufferdEventFlushStorategy(timeInterval: 5, limitOnNumberOfEvent: 10)

    // loggerの宣言
    let loggerBundler = LoggerBundler(
        components: [HogelLogger()],
        buffer: buffer,
        loggingStorategy: storategy
    )

    // プールの監視を開始
    loggerBundler.startLogging()
    
    return loggerBundler
}
