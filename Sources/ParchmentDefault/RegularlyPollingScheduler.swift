//
//  File.swift
//  
//
//  Created by k-kohey on 2021/12/29.
//

import Parchment
import Foundation

public final class RegularlyPollingScheduler: BufferdEventFlushScheduler {
    public static let `default` = RegularlyPollingScheduler(timeInterval: 60)
    
    let timeInterval: TimeInterval
    let limitOnNumberOfEvent: Int
    
    var lastFlushedDate: Date = Date()
    
    private var timer: Timer?
    
    public init(
        timeInterval: TimeInterval,
        limitOnNumberOfEvent: Int = .max,
        dispatchQueue: DispatchQueue? = nil
    ) {
        self.timeInterval = timeInterval
        self.limitOnNumberOfEvent = limitOnNumberOfEvent
    }
    
    public func schedule(with buffer: TrackingEventBufferAdapter, didFlush: @escaping ([BufferRecord])->()) {
        DispatchQueue.main.async { [weak self] in
            self?.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                guard let self = self else { return }
                Task {
                    await self.tick(with: buffer, didFlush: didFlush)
                }
            }
        }
    }
    
    private func tick(with buffer: TrackingEventBufferAdapter, didFlush: @escaping ([BufferRecord])->()) async {
        guard await buffer.count() > 0 else { return }
        
        let flush = {
            let records = await buffer.dequeue()
            
//            console()?.log("✨ Flush \(records.count) event")
            didFlush(records)
        }
        
        let count = await buffer.count()
        if self.limitOnNumberOfEvent < count {
            await flush()
            return
        }
        
        let timeSinceLastFlush = abs(self.lastFlushedDate.timeIntervalSinceNow)
        if self.timeInterval < timeSinceLastFlush {
            await flush()
            self.lastFlushedDate = Date()
            return
        }
    }
}
