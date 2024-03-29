//
//  SQLiteBuffer.swift
//
//
//  Created by k-kohey on 2021/10/27.
//

@_spi(ParchmentCore) import ParchmentCore
import SQLite
import Foundation

public final actor SQLiteBuffer: LogBuffer {
    private enum Column {
        static let event = Expression<Data>("event")
        static let timestamp = Expression<Date>("timestamp")
    }

    private let db: Connection
    private let events: Table

    public var encoder = JSONEncoder()
    public var decoder = JSONDecoder()

    public init(tableName: String = "Events") throws {
        let dbFilePath = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("\(tableName).sqlite3")

        db = try Connection(dbFilePath.absoluteString)
        events = Table(tableName)


        try db.run(
            events.create(ifNotExists: true) { t in
                t.column(Column.event, primaryKey: true)
                t.column(Column.timestamp)
            }
        )
    }

    public func enqueue(_ e: [Payload]) throws {
        try db.run(
            try events.insertMany(
                e.map {
                    [
                        Column.event <- try encoder.encode($0),
                        Column.timestamp <- $0.timestamp
                    ]
                }
            )
        )

        osLogger.debug(
            "🎁 Buffer \(e.count) events\n\(e.reduce("", { $0 + "\($1)\n" }))"
        )
    }

    public func dequeue(limit: Int?) throws -> [Payload] {
        let target = events.order(Column.timestamp).limit(limit)
        let entities = try db.prepare(target)
            .map { $0[Column.event] }
            .joined(separator: ",".data(using: .utf8)!)
        let jsonData = "[".data(using: .utf8)! + entities + "]".data(using: .utf8)!

        let result = try decoder.decode([Payload].self, from: jsonData)

        if limit != nil {
            // Cannot Delete if limit is not specified
            try db.run(target.delete())
        } else {
            try db.run(events.delete())
        }

        return result
    }

    public func count() throws -> Int {
        try db.scalar(events.count)
    }

    public func clear() throws {
        try db.run(events.drop())
    }
}
