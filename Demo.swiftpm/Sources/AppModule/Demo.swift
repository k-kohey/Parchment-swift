import SwiftUI
import Parchment
import ParchmentDefault

extension LoggerComponentID {
    static let my: Self = .init("My")
}

struct MyLogger: LoggerComponent {
    static let id: LoggerComponentID = .my

    func send(_ log: [LoggerSendable]) async -> Bool {
        print("send \(log)")
        try? await Task.sleep(nanoseconds: 1000_000)
        return true
    }
}

extension TrackingEvent {
    static func impletion(_ screen: String) -> Self {
        TrackingEvent(eventName: "impletion", parameters: ["screen": screen])
    }

    static var tap: Self {
        .init(eventName: "tap", parameters: [:])
    }
}

let logger = LoggerBundler.make(
    components: [MyLogger()],
    loggingStrategy: RegularlyPollingScheduler(timeInterval: 5)
)

@main
struct ExampleAppApp: App {
    var body: some Scene {
        WindowGroup {
            Button("send event") {
                Task {
                    await logger.send(event: .tap, with: .init(policy: .bufferingFirst))
                }
            }
            .task {
                await logger.startLogging()
                await logger.send(event: .impletion("home"))
            }
        }
    }
}
