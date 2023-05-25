//
//  File.swift
//  
//
//  Created by Kohei Kawaguchi on 2023/05/22.
//

import SwiftUI

public struct ImpletionEvent: Loggable {
    public var eventName = "ImpletionEvent"
    public var parameters: [String : Sendable]
}

private struct Impletion: ViewModifier {
    let screenName: String
    let logger: LoggerBundler
    let option: LoggerBundler.LoggingOption?

    func body(content: Content) -> some View {
        content.onAppear {
            Task {
                let e = ImpletionEvent(
                    parameters: [
                        "screen": screenName
                    ]
                )
                if let option {
                    await logger.send(e, with: option)
                } else {
                    await logger.send(e)
                }
            }
        }
    }
}

public extension View {
    /// Hook onAppear to send ImpletionEvent
    func track(
        screen name: String,
        with logger: LoggerBundler,
        option: LoggerBundler.LoggingOption? = nil
    ) -> some View {
        modifier(
            Impletion(
                screenName: name,
                logger: logger,
                option: option
            )
        )
    }
}
