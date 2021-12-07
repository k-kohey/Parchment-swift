import XCTest
import class Foundation.Bundle
@testable import Poolep

final class SQLiteBufferTests: XCTestCase {
    private var buffer: SQLiteBuffer!
    
    static override func setUp() {
        Configuration.debugMode = true
    }
    
    override func setUp() {
        self.buffer = try! SQLiteBuffer()
        self.buffer.clear()
    }
    
    func testDequeue() throws {
        let record = BufferRecord(destination: "hoge", eventName: "a", parameters: [:], timestamp: .init(timeIntervalSince1970: 0))

        buffer.enqueue([record])
        let results = buffer.dequeue(limit: 1)
        
        XCTAssertEqual(results.first, record)
        XCTAssertEqual(buffer.count(), 0)
    }
    
    func testDequeue_whenMultipleRecordsWereInserted() {
        let records = makeRecords()
        
        buffer.enqueue(records)
        
        let results = buffer.dequeue()
        XCTAssertEqual(results, records)
        XCTAssertEqual(buffer.count(), 0)
    }
    
    func testCount() {
        let records = makeRecords()
        
        buffer.enqueue(records)
        
        let results = buffer.count()
        XCTAssertEqual(results, records.count)
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
