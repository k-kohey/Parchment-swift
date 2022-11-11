import class Foundation.Bundle
@testable import Parchment
@testable import ParchmentDefault
import XCTest

final class SQLiteBufferTests: XCTestCase {
    private var buffer: SQLiteBuffer!

    @MainActor
    override static func setUp() {
        Configuration.debugMode = true
    }

    override func setUp() {
        self.buffer = try! SQLiteBuffer()
        Task {
            await self.buffer.clear()
        }
    }

    func testDequeue() async throws {
        let record = BufferRecord(destination: "hoge", eventName: "a", parameters: [:], timestamp: .init(timeIntervalSince1970: 0))

        await buffer.save([record])
        let results = await buffer.load(limit: 1)
        let count = await buffer.count()

        XCTAssertEqual(results.first, record)
        XCTAssertEqual(count, 0)
    }

    func testDequeue_whenMultipleRecordsWereInserted() async {
        let records = makeRecords()

        await buffer.save(records)

        let results = await buffer.load()
        let count = await buffer.count()

        XCTAssertEqual(results, records)
        XCTAssertEqual(count, 0)
    }

    func testCount() async {
        let records = makeRecords()

        await buffer.save(records)
        let results = await buffer.count()

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
