// 
//  File.swift
//  
//
//  Created by k-kohey on 2021/10/08.
//

import Foundation

public protocol BufferdEventFlushStorategy {
    func schedule(with buffer: TrackingEventBuffer, didFlush: @escaping ([BufferRecord])->())
}

public class RegularlyBufferdEventFlushStorategy: BufferdEventFlushStorategy {
    public static let `default` = RegularlyBufferdEventFlushStorategy(timeInterval: 60)
    
    let timeInterval: TimeInterval
    let limitOnNumberOfEvent: Int
    
    var lastFlushedDate: Date = Date()
    
    private var timer: Timer?
    private let dispatchQueue: DispatchQueue
    
    
    public init(
        timeInterval: TimeInterval,
        limitOnNumberOfEvent: Int = .max,
        dispatchQueue: DispatchQueue? = nil
    ) {
        self.timeInterval = timeInterval
        self.limitOnNumberOfEvent = limitOnNumberOfEvent
        self.dispatchQueue = dispatchQueue ?? .readWrite
    }
    
    public func schedule(with buffer: TrackingEventBuffer, didFlush: @escaping ([BufferRecord])->()) {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.tick(with: buffer, didFlush: didFlush)
        }
        
        // for debug on command line tool
        RunLoop.current.add(timer!, forMode: .default)
    }
    
    private func tick(with buffer: TrackingEventBuffer, didFlush: @escaping ([BufferRecord])->()) {
        self.dispatchQueue.async { [weak self] in
            guard let self = self, buffer.count() > 0 else { return }
            
            let flush = {
                let records = buffer.dequeue(limit: .max)
                print("""
                
                ==============================================
                
                ✨ Flush \(records.count) event
                
                ----------------------------------------------
                
                """)
                didFlush(records)
                
                print("\n==============================================")
            }
            
            if self.limitOnNumberOfEvent < buffer.count() {
                flush()
                return
            }
            
            let timeSinceLastFlush = abs(self.lastFlushedDate.timeIntervalSinceNow)
            if self.timeInterval < timeSinceLastFlush {
                flush()
                self.lastFlushedDate = Date()
                return
            }
        }
    }
}
