import Parchment

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
}

let logger = LoggerBundler(
    components: [MyLogger()]
)
