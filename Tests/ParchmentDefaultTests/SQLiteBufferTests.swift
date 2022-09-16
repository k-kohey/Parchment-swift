import class Foundation.Bundle
@testable import Parchment
@testable import ParchmentDefault
import XCTest

final class SQLiteBufferTests: XCTestCase {
    private var buffer: SQLiteBuffer!

    override static func setUp() {
        Configuration.debugMode = true
    }

    override func setUp() {
        self.buffer = try! SQLiteBuffer()
        self.buffer.clear()
    }

    func testDequeue() throws {
        let record = BufferRecord(destination: "hoge", eventName: "a", parameters: [:], timestamp: .init(timeIntervalSince1970: 0))

        buffer.save([record])
        let results = buffer.load(limit: 1)

        XCTAssertEqual(results.first, record)
        XCTAssertEqual(buffer.count(), 0)
    }

    func testDequeue_whenMultipleRecordsWereInserted() {
        let records = makeRecords()

        buffer.save(records)

        let results = buffer.load()
        XCTAssertEqual(results, records)
        XCTAssertEqual(buffer.count(), 0)
    }

    func testCount() {
        let records = makeRecords()

        buffer.save(records)

        let results = buffer.count()
        XCTAssertEqual(results, records.count)
    }

    private func makeRecords() -> [BufferRecord] {
        (0 ..< 10).compactMap {
            .init(
                destination: "hoge",
                eventName: "a",
                parameters: [:],
                timestamp: .init(timeIntervalSince1970: TimeInterval($0))
            )
        }
    }
}
