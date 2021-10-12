import Logger

extension LoggerComponentID {
    static let mixpanel: Self = .init("Mixpanel")
    static let api: Self = .init("AnalyticsAPI")
}

struct MixpanelLogger: LoggerComponent {
    static var id: LoggerComponentID = .mixpanel
    
    func send(_ e: Loggable) -> Bool {
        // do logging
        print("log: \(e)")
        return true
    }
    
    func setCustomProperty(_ : [String: String]) {
        // do anything
    }
}

struct AnalyticsAPILogger: LoggerComponent {
    static var id: LoggerComponentID = .api
    
    func send(_ e: Loggable) -> Bool {
        // do logging
        print("log: \(e)")
        return true
    }
    
    func setCustomProperty(_ : [String: String]) {
        // do anything
    }
}

enum Event: Loggable {
    case touch(button: String)
    
    var eventName: String {
        "\(self)"
    }
    
    var parameters: [String : String] {
        switch self {
        case .touch(let screen):
            return ["screen": screen]
        }
    }
}

// debug用の実装
class EventQueue: TrackingEventBuffer {
    private var records: [BufferRecord] = []
    
    func enqueue(_ e: BufferRecord) {
        records.append(e)
    }
    
    func dequeue() -> BufferRecord? {
        defer {
            records.removeFirst()
        }
        return records.first
    }
    
    func dequeue(limit: Int) -> [BufferRecord] {
        (0..<limit).reduce([]) { result, _ in
            result + [dequeue()].compactMap { $0 }
        }
    }
    
    func count() -> Int {
        records.count
    }
}

extension ExpandableLoggingEvent {
    static let impletion = ExpandableLoggingEvent(eventName: "impletion", parameters: [:])
}

// ログの送信先を宣言
let mixpanel = MixpanelLogger()
let own = AnalyticsAPILogger()

// ユーザプロパティの設定は個別に行う
mixpanel.setCustomProperty(["user_id": "hogehoge1010"])

// イベントをプールするデータベースを宣言
let buffer = EventQueue()

// どのようなロジックでプールしたイベントをバックエンドに送信するかを宣言
// 今回の場合は1分間に1回プールして送信するように初期値を設定
let storategy = RegularlyBufferdEventLoggingStorategy(timeInterval: 60)

// loggerの宣言
let loggerBundler = LoggerBundler(
    components: [mixpanel, own],
    buffer: buffer,
    loggingStorategy: storategy
)

// プールの監視を開始
loggerBundler.startLogging()

// プールにためて任意のタイミングでログを送信
loggerBundler.send(Event.touch(button: "purchaseButton"), with: .init(policy: .bufferingFirst))
loggerBundler.send(.screenStart(name: "home"), with: .init(policy: .bufferingFirst, scope: .exclude([.api])))

// プールに貯めずに直ちにログを送信
loggerBundler.send(.impletion, with: .init(policy: .immediately))

