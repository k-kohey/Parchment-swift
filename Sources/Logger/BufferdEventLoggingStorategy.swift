// 
//  File.swift
//  
//
//  Created by k-kohey on 2021/10/08.
//

import Foundation

public protocol BufferdEventLoggingStorategy {
    func schedule(with buffer: TrackingEventBuffer, willLog: @escaping ([Loggable])->())
}

public class RegularlyBufferdEventLoggingStorategy: BufferdEventLoggingStorategy {
    public static let `default` = RegularlyBufferdEventLoggingStorategy(timeInterval: 60)
    
    let timeInterval: TimeInterval
    private var timer: Timer?
    
    public init(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
    }
    
    
    public func schedule(with buffer: TrackingEventBuffer, willLog: @escaping ([Loggable])->()) {
        timer = .init(timeInterval: timeInterval, repeats: true) { _ in
            let bufferdEvent = buffer.load()
            willLog(bufferdEvent)
        }
    }
}
