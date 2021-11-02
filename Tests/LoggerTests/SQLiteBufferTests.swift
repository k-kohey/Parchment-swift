import XCTest
import class Foundation.Bundle
@testable import Logger

final class SQLiteBufferTests: XCTestCase {
    private var buffer: SQLiteBuffer!
    
    static override func setUp() {
        Logger.Configuration.shouldPrintDebugLog = true
    }
    
    override func setUp() {
        self.buffer = try! SQLiteBuffer()
        self.buffer.clear()
    }
    
    func testDequeue() throws {
        let record = BufferRecord(destination: "hoge", eventName: "a", parameters: [:], timestamp: .init(timeIntervalSince1970: 0))

        buffer.enqueue(record)
        let recors = buffer.dequeue(limit: 1)
        
        XCTAssertEqual(recors.count, 1)
        XCTAssertEqual(recors.first, record)
    }
    
    func testDequeue_whenMultipleRecordsWereInserted() {
        let records = makeRecords()
        
        records.forEach {
            buffer.enqueue($0)
        }
        
        let results = buffer.dequeue(limit: .max)
        XCTAssertEqual(results, records)
    }
    
    private func makeRecords() -> [BufferRecord] {
        (0..<10).compactMap {
            .init(
                destination: "hoge",
                eventName: "a",
                parameters: [:],
                timestamp: .init(timeIntervalSince1970: TimeInterval($0))
            )
        }
    }
}
