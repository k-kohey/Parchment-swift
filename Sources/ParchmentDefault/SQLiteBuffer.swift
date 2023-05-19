//
//  SQLiteBuffer.swift
//
//
//  Created by k-kohey on 2021/10/27.
//

import Parchment
import SQLite
import Foundation

public final actor SQLiteBuffer: TrackingEventBuffer {
    private enum Column {
        static let id = Expression<String>("id")
        static let destination = Expression<String>("destination")
        static let eventName = Expression<String>("eventName")
        static let parameters = Expression<Data>("parameters")
        static let timestamp = Expression<Date>("timestamp")
    }

    private let db: Connection
    private let events: Table

    public init(tableName: String = "Events") throws {
        let dbFilePath = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("Events.sqlite3")

        db = try Connection(dbFilePath.absoluteString)
        events = Table(tableName)


        try db.run(
            events.create(ifNotExists: true) { t in
                t.column(Column.id, primaryKey: true)
                t.column(Column.destination)
                t.column(Column.eventName)
                t.column(Column.parameters)
                t.column(Column.timestamp)
            }
        )
    }

    public func save(_ e: [BufferRecord]) throws {
        try db.run(
            try events.insertMany(
                e.map {
                    let parameters: Data
                    if JSONSerialization.isValidJSONObject($0.parameters) {
                        parameters = try JSONSerialization.data(withJSONObject: $0.parameters)
                    } else {
                        parameters = .init()
                    }
                    return [
                        Column.id <- $0.id,
                        Column.destination <- $0.destination,
                        Column.eventName <- $0.eventName,
                        Column.parameters <- parameters,
                        Column.timestamp <- $0.timestamp
                    ]
                }
            )
        )
    }

    public func load(limit: Int?) throws -> [BufferRecord] {
        let target = events.order(Column.timestamp).limit(limit)
        let result = try db.prepare(target).map { row in
            let p = try JSONSerialization.jsonObject(with: row[Column.parameters])
            return BufferRecord(
                id: row[Column.id],
                destination: row[Column.destination],
                eventName: row[Column.eventName],
                parameters: p as! [String: Sendable],
                timestamp: row[Column.timestamp]
            )
        }

        if limit != nil {
            // Cannot Delete if limit is not specified
            try db.run(target.delete())
        } else {
            try db.run(events.delete())        }

        return result
    }

    public func count() throws -> Int {
        try db.scalar(events.count)
    }

    public func clear() throws {
        try db.run(events.drop())
    }
}
