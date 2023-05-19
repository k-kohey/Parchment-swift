import SwiftUI
import Parchment
import ParchmentDefault

extension LoggerComponentID {
    static let my: Self = .init("My")
}

struct MyLogger: LoggerComponent {
    static let id: LoggerComponentID = .my

    func send(_ log: [LoggerSendable]) async -> Bool {
        print("🚀 Send \(log.count) events\n \(log.reduce("", { $0 + "\($1)\n" }))")
        try? await Task.sleep(nanoseconds: 1000_000)
        return true
    }
}

extension TrackingEvent {
    static func impletion(_ screen: String) -> Self {
        TrackingEvent(eventName: "impletion", parameters: ["screen": screen])
    }

    static var tapIncrement: Self {
        .init(eventName: "tap increment", parameters: [:])
    }

    static var tapDecrement: Self {
        .init(eventName: "tap decrement", parameters: [:])
    }
}

let logger = LoggerBundler.make(
    components: [MyLogger()],
    loggingStrategy: RegularlyPollingScheduler(timeInterval: 5)
)

@main
struct ExampleAppApp: App {
    @State @Tracked(name: "count", with: logger) var count: Int = 0
    @State @Tracked(name: "text", with: logger, scope: \.description) var text = ""

    var body: some Scene {
        WindowGroup {
            VStack {
                TextEditor(text: $text.erase())
                    .lineLimit(nil)
                Stepper(
                    onIncrement: {
                        count += 1
                        Task {
                            await logger.send(event: .tapIncrement)
                        }
                    },
                    onDecrement: {
                        count -= 1
                        Task {
                            await logger.send(event: .tapDecrement)
                        }
                    },
                    label: {
                        Text("\(count)")
                    }
                )
            }
            .padding()
            .background(Color.gray)
            .task {
                await logger.startLogging()
                await logger.send(event: .impletion("home"))
            }
        }
    }
}
