import SwiftUI
import Parchment
import ParchmentDefault

extension LoggerComponentID {
    static let my: Self = .init("My")
}

struct MyLogger: LoggerComponent {
    static var id: LoggerComponentID = .my
    
    func send(_ log: [LoggerSendable]) async -> Bool {
        print("send \(log)")
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
    components: [MyLogger()]
)


@main
struct ExampleAppApp: App {
    var body: some Scene {
        WindowGroup {
            Button("send event") {
                Task {
                    await logger.send(.tap)
                }
            }
            .onAppear {
                logger.startLogging()
                Task {
                    await logger.send(.impletion("home"))
                }
            }
        }
    }
}

