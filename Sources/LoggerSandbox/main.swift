import Logger
import Foundation

extension LoggerComponentID {
    static let mixpanel: Self = .init("Mixpanel")
    static let firebase: Self = .init("Firebase")
    static let fail: Self = .init("fail")
}

struct MixpanelLogger: LoggerComponent {
    static var id: LoggerComponentID = .mixpanel
    
    func send(_ e: Loggable) -> Bool {
        // do logging
        print("🚀 send to mixpanel:\n   =>\(e)")
        return true
    }
    
    func setCustomProperty(_ : [String: String]) {
        // do anything
    }
}

struct FirebaseLogger: LoggerComponent {
    static var id: LoggerComponentID = .firebase
    
    func send(_ e: Loggable) -> Bool {
        // do logging
        print("🚀 send to firebase:\n   =>\(e)")
        return true
    }
    
    func setCustomProperty(_ : [String: String]) {
        // do anything
    }
}

struct FailLogger: LoggerComponent {
    static var id: LoggerComponentID = .fail
    
    func send(_ e: Loggable) -> Bool {
        false
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

    var parameters: [String : Any] {
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

extension ExpandableLoggingEvent {
    static let impletion = ExpandableLoggingEvent(eventName: "impletion", parameters: [:])
}

// ログの送信先を宣言
let mixpanel = MixpanelLogger()
let firebase = FirebaseLogger()
let fail = FailLogger()

// ユーザプロパティの設定は個別に行う
mixpanel.setCustomProperty(["user_id": "hogehoge1010"])


func makeLogger() -> LoggerBundler {
    Logger.Configuration.shouldPrintDebugLog = true
    
    // イベントをプールするデータベースを宣言
    let buffer = EventQueue()

    // どのようなロジックでプールしたイベントをバックエンドに送信するかを宣言
    let storategy = RegularlyBufferdEventFlushStorategy(timeInterval: 5, limitOnNumberOfEvent: 10)

    // loggerの宣言
    let loggerBundler = LoggerBundler(
        components: [mixpanel, firebase, fail],
        buffer: buffer,
        loggingStorategy: storategy
    )
    
    loggerBundler.configMap = [.fail: .init(allowBuffering: false)]

    // プールの監視を開始
    loggerBundler.startLogging()
    
    return loggerBundler
}

var logger: LoggerBundler!

func poolに貯めずに直ちにログを送信() {
    logger = makeLogger()
    logger.send(.impletion, with: .init(policy: .immediately))
}

func poolの限界値以上のログをためたら直ちにログを送信() {
    logger = makeLogger()
    for _ in 0..<11 {
        logger.send(.impletion, with: .init(scope: .only([.firebase])))
    }
}

func poolにためて任意のタイミングでログを送信() {
    logger = makeLogger()
    logger.send(Event.touch(button: "purchaseButton"), with: .init(policy: .bufferingFirst))
    logger.send(.screenStart(name: "home"), with: .init(policy: .bufferingFirst, scope: .only([.firebase])))
}


makeLogger().send(Event.touch(button: "purchaseButton"), with: .init(policy: .immediately))

// for buffering debug
RunLoop.current.run()
