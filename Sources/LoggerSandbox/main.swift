import Logger

struct MixpanelLogger: LoggerComponent {
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

struct EventDataBase: TrackingEventBuffer {
    func save(_: [BufferRecord]) {
        
    }
    
    func load() -> [Loggable] {
        []
    }
    
    func count() -> Int {
        0
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
let db = EventDataBase()

// どのようなロジックでプールしたイベントをバックエンドに送信するかを宣言
// 今回の場合は1分間に1回プールして送信するように初期値を設定
let storategy = RegularlyBufferdEventLoggingStorategy(timeInterval: 60)

// loggerの宣言
let loggerBundler = LoggerBundler(
    components: [mixpanel, own],
    buffer: db,
    loggingStorategy: storategy
)

// プールの監視を開始
loggerBundler.startLogging()

// プールにためて任意のタイミングでログを送信
loggerBundler.send(Event.touch(button: "purchaseButton"), with: .buffering)
loggerBundler.send(.screenStart(name: "home"), with: .buffering)

// プールに貯めずに直ちにログを送信
loggerBundler.send(.impletion, with: .immediately)

