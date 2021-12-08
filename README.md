# Parchment-ios

Parchment is implemention called Logger or Tracker. 
Parchment has three features:

1. Retrying when logging request is failed.
2. Log is buffed and can be sent at any time.
3. Easy to combine your source code and replace logger implemention.

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
