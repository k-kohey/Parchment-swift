# Parchment-ios

Parchment is implemention called Logger or Tracker. 
Parchment has three features:

1. Retrying when logging request is failed.
2. Log is buffed and can be sent at any time.
3. Easy to combine your source code and replace logger implemention.

# [WIP]API Document

- https://k-kohey.github.io/Parchment-swift/Parchment/documentation/parchment/
- https://k-kohey.github.io/Parchment-swift/ParchmentDefault/documentation/parchmentdefault/

# Usage

## 1. Definision logging event


```swift

// with struct
struct Event: Loggable {
    public let eventName: String
    public let parameters: [String : Any]
}

// with enum
enum Event: Loggable {
  case impletion(screen: String)
  
  var eventName: String {
    ...
  }

  var parameters: [String : Any] {
    ...
  }
}

```

Alternatively, there are two ways to do this without definision logging event.

- Use type `TrackingEvent`
- Use Dictionary. Dictionary is conformed Loggable.

## 2. Wrap logging service

Wrap existing logger implemention such as such as FirebaseAnalytics and endpoints with LoggerComponent.

```swift

extension LoggerComponentID {
    static let analytics = LoggerComponentID("Analytics")
}

struct Analytics: LoggerComponent {
    static let id: LoggerComponentID = .analytics

    func send(_ event: Loggable) async -> Bool {
        let url = URL(string: "https://your-endpoint/...")!
        request.httpBody = convertBody(from: event)
        
        return await withCheckedContinuation { continuation in
            let task = URLSession.shared.dataTask(with: request) { data, response, error in

                if let error = error {
                    print(error)
                    continuation.resume(returning: false)
                    return
                }
                
                guard
                    let response = response as? HTTPURLResponse,
                    (200..<300).contains(response.statusCode)
                else {
                    continuation.resume(returning: false)
                    return
                }
                
                continuation.resume(returning: true)
            }
            task.resume()
        }
    }
}

```

## 3. Send event

Initialize `LoggerBundler` and send log using it.

```swift

let analytics = Analytics()
let logger = LoggerBundler(components: [analytics])

await logger.send(
    TrackingEvent(eventName: "hoge", parameters: [:]),
    with: .init(policy: .immediately)
)

await logger.send(.impletion(screen: "Home"))

await logger.send([\.eventName: "tapButton", \.parameters: ["ButtonID": 1]])

```

# Customization

This section describes how to customize the behavior of the logger.

## Create a type that conforms to Mutation

Mutation converts one log into another. 

This is useful if you have parameters that you want to add to all the logs.

To create the type and set it to logger, write as follows.

```swift

// An implementation similar to this can be found in ParchmentDefault

struct DeviceDataMutation: Mutation {
    private let deviceParams = [
        "Model": UIDevice.current.name,
        "OS": UIDevice.current.systemName,
        "OS Version": UIDevice.current.systemVersion
    ]
    
    public func transform(_ event: Loggable, id: LoggerComponentID) -> Loggable {
        let log: LoggableDictonary = [
            \.eventName: event.eventName,
            \.parameters: event.parameters.merging(deviceParams) { left, _ in left }
        ]
        return log
    }
}

logger.mutations.append(DeviceDataMutation())

```

## Extend LoggerComponentID

LoggerComponentID is an ID that uniquely recognizes a logger.

By extending LoggerComponentID, the destination of the log can be controlled as shown below.


```swift

extension LoggerComponentID {
    static let firebase: Self = .init("firebase")
    static let myBadkend: Self = .init("myBadkend")
}

await logger.send(.tap, with: .init(scope: .exclude([.firebase, .myBadkend])))

await logger.send(.tap, with: .init(scope: .only([.myBadkend])))

```

## Create a type that conforms to BufferedEventFlushScheduler

BufferedEventFlushScheduler determines the timing of fetching the log data in the buffer.
To create the type and set it to logger, write as follows.


```swift

// An implementation similar to this can be found in ParchmentDefault
final class RegularlyPollingScheduler: BufferedEventFlushScheduler {
    public static let `default` = RegularlyPollingScheduler(timeInterval: 60)
    
    let timeInterval: TimeInterval
    
    var lastFlushedDate: Date = Date()
    
    private weak var timer: Timer?
    
    public init(
        timeInterval: TimeInterval,
    ) {
        self.timeInterval = timeInterval
    }
    
    public func schedule(with buffer: TrackingEventBufferAdapter) async -> AsyncThrowingStream<[BufferRecord], Error> {
        return AsyncThrowingStream { continuation in
            let timer = Timer(fire: .init(), interval: 1, repeats: true) { _ in
                Task { [weak self] in
                    await self?.tick(with: buffer) {
                        continuation.yield($0)
                    }
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
        }
    }
    
    public func cancel() {
        timer?.invalidate()
    }
    
    private func tick(with buffer: TrackingEventBufferAdapter, didFlush: @escaping ([BufferRecord])->()) async {
        guard await buffer.count() > 0 else { return }
        
        let flush = {
            let records = await buffer.load()
            didFlush(records)
        }
        
        let timeSinceLastFlush = abs(self.lastFlushedDate.timeIntervalSinceNow)
        if self.timeInterval < timeSinceLastFlush {
            await flush()
            self.lastFlushedDate = Date()
            return
        }
    }
}

let logger = LoggerBundler(
    components: [...],
    buffer: TrackingEventBuffer = ...,
    loggingStrategy: BufferedEventFlushScheduler = RegularlyPollingScheduler.default
)

```

## Create a type that conforms to TrackingEventBuffer

TrackingEventBuffer is a buffer that saves the log.

ParchmentDefault defines a class SQLiteBuffer that uses SQLite to store logs.

This implementation can be replaced by a class that is compatible with TrackingEventBuffer.
