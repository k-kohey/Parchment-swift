@testable import Parchment
@testable import ParchmentDefault
import XCTest

final class SQLiteBufferTests: XCTestCase {
    override func setUp() async throws {
        try await SQLiteBuffer().clear()
    }

    func testLoad() async throws {
        let db = try SQLiteBuffer()

        let records = [
            Payload(
                destination: "hoge",
                eventName: "a",
                parameters: [:],
                timestamp: .init(timeIntervalSince1970: 0)
            ),
            Payload(
                destination: "fuga",
                eventName: "b",
                parameters: ["a": 0, "b": "c"],
                timestamp: .init(timeIntervalSince1970: 0)
            ),
            Payload(
                destination: "foo",
                eventName: "c",
                parameters: ["a": 0, "b": "c"],
                timestamp: .init(timeIntervalSince1970: 0)
            )
        ]

        try await db.enqueue(records)
        let results = try await db.load()

        XCTAssertEqual(
            results,
            records
        )
    }

    func testCount() async throws {
        let db = try SQLiteBuffer()

        let records = [
            Payload(
                destination: "hoge",
                eventName: "a",
                parameters: [:],
                timestamp: .init(timeIntervalSince1970: 0)
            ),
            Payload(
                destination: "fuga",
                eventName: "b",
                parameters: ["a": 0, "b": "c"],
                timestamp: .init(timeIntervalSince1970: 0)
            ),
            Payload(
                destination: "foo",
                eventName: "c",
                parameters: ["a": 0, "b": "c"],
                timestamp: .init(timeIntervalSince1970: 0)
            )
        ]

        let initalState = try await db.count()
        XCTAssertEqual(initalState, 0)

        do {
            try await db.enqueue(records)
            let result = try await db.count()
            XCTAssertEqual(result, 3)
        }

        do {
            _ = try await db.load()
            let result = try await db.count()
            XCTAssertEqual(result, 0)
        }
    }

    func testLoad_with_limit() async throws {
        let db = try SQLiteBuffer()

        let records = [
            Payload(
                destination: "hoge",
                eventName: "a",
                parameters: [:],
                timestamp: .init(timeIntervalSince1970: 2)
            ),
            Payload(
                destination: "fuga",
                eventName: "b",
                parameters: ["a": 0, "b": "c"],
                timestamp: .init(timeIntervalSince1970: 1)
            ),
            Payload(
                destination: "foo",
                eventName: "c",
                parameters: ["a": 0, "b": "c"],
                timestamp: .init(timeIntervalSince1970: 3)
            )
        ]

        try await db.enqueue(records)
        let result = try await db.dequeue(limit: 2)

        let count = try await db.count()
        XCTAssertEqual(count, 1)
        XCTAssertEqual(
            result,
            result.sorted { lhs, rhs in
                lhs.timestamp < rhs.timestamp
            }
        )
    }
}
