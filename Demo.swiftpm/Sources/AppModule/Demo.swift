import SwiftUI
import Parchment
import ParchmentDefault

extension LoggerComponentID {
    static let my: Self = .init("My")
}

struct MyLogger: LoggerComponent {
    static let id: LoggerComponentID = .my

    func send(_ log: [LoggerSendable]) async -> Bool {
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

struct TimestampMutation: Mutation {
    func transform(_ e: Parchment.Loggable, id: Parchment.LoggerComponentID) -> Parchment.AnyLoggable {
        var e = AnyLoggable(e)
        e.parameters["createdAt"] = Date()
        return e
    }
}

struct UserIDMutation: Mutation {
    let userID = 1

    func transform(_ e: Parchment.Loggable, id: Parchment.LoggerComponentID) -> Parchment.AnyLoggable {
        var e = AnyLoggable(e)
        e.parameters["userID"] = userID
        return e
    }
}

let logger = LoggerBundler.make(
    components: [MyLogger(), DebugLogger()],
    bufferFlowController: DefaultBufferFlowController(pollingInterval: 5, delayInputLimit: 5)
)

@main
struct ExampleAppApp: App {
    @State var count: Int = 0
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

                await logger.add(
                    mutations: [TimestampMutation(), UserIDMutation()]
                )

                await logger.send(event: .impletion("home"))
            }
            .track(
                screen: "Top",
                with: logger
            )
        }
    }
}
