// 
//  File.swift
//  
//
//  Created by k-kohey on 2021/10/27.
//

import Foundation
import SQLite3

public final class SQLiteBuffer: TrackingEventBuffer {
    enum SQLiteBufferError: Error {
        case dbfileCanNotBeenOpend
        case failedToCreateSQLiteTable
    }
    
    private var dbPointer: OpaquePointer?
    
    public init() throws {
        let dbFilePath = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ).appendingPathComponent("Events.db")
        
        print("Events.db is created on \(dbFilePath.absoluteString)")
        
        if sqlite3_open(dbFilePath.path, &dbPointer) != SQLITE_OK {
            throw SQLiteBufferError.dbfileCanNotBeenOpend
        }
        
        if sqlite3_exec(
            dbPointer,
            """
            CREATE TABLE IF NOT EXISTS Events (
                id TEXT PRIMARY KEY,
                destination TEXT NOT NULL,
                timestamp TIMESTAMP NOT NULL,
                eventName TEXT NOT NULL,
                parameters TEXT NOT NULL
            )
            """,
            nil,
            nil,
            nil
        ) != SQLITE_OK {
            throw SQLiteBufferError.failedToCreateSQLiteTable
        }
    }
    
    public func enqueue(_ e: [BufferRecord]) {
        let query = """
        INSERT INTO Events (
            id,
            destination,
            timestamp,
            eventName,
            parameters
        ) VALUES \(e.map { _ in "(?, ?, ?, ?, ?)" }.joined(separator: ", "))
        """
        
        let context = prepare(query: query)
        
        defer {
            sqlite3_finalize(context)
        }
        
        for (index, e) in e.enumerated() {
            let valueIndex = { (offset: Int) -> Int32 in
                let numberOfColumns = 5
                return Int32(index * numberOfColumns + offset)
            }
            if sqlite3_bind_text(context, valueIndex(1), e.id.utf8String, -1, nil) != SQLITE_OK {
                assertionWithLastErrorMessage()
                return
            }
            
            if sqlite3_bind_text(context, valueIndex(2), e.destination.utf8String, -1, nil) != SQLITE_OK {
                assertionWithLastErrorMessage()
                return
            }
            
            if sqlite3_bind_int64(context, valueIndex(3), sqlite3_int64(e.timestamp.timeIntervalSince1970)) != SQLITE_OK {
                assertionWithLastErrorMessage()
                return
            }
            
            if sqlite3_bind_text(context, valueIndex(4), e.eventName.utf8String, -1, nil) != SQLITE_OK {
                assertionWithLastErrorMessage()
                return
            }
            
            do {
                let parameters = try JSONSerialization.data(withJSONObject: e.parameters)
                if
                    let string = String(data: parameters, encoding: .utf8),
                    sqlite3_bind_text(context, valueIndex(5), string, -1, nil) != SQLITE_OK
                {
                    assertionWithLastErrorMessage()
                    return
                }
            }
            catch {
                assertionFailure("\(error).")
                return
            }
        }
        
        if sqlite3_step(context) != SQLITE_DONE {
            assertionWithLastErrorMessage()
            return
        }
    }
    
    public func dequeue(limit: Int64) -> [BufferRecord] {
        let query: String
        if limit < 0 {
            query = "SELECT * FROM Events ORDER BY timestamp"
        } else {
            query = "SELECT * FROM Events ORDER BY timestamp LIMIT ?"
        }
        let context = prepare(query: query)
        
        defer {
            sqlite3_finalize(context)
        }
        
        
        if 0 < limit, sqlite3_bind_int64(context, 1, Int64(limit)) != SQLITE_OK {
            assertionWithLastErrorMessage()
            return []
        }
         
        var result: [BufferRecord] = []
        
        while(sqlite3_step(context) == SQLITE_ROW) {
            let id = String(cString: sqlite3_column_text(context, 0))
            let destination = String(cString: sqlite3_column_text(context, 1))
            let timestamp = sqlite3_column_int64(context, 2)
            let eventName = String(cString: sqlite3_column_text(context, 3))

            let parameters: [String: Any] = {
                guard let bytes = sqlite3_column_blob(context, 4) else  { return [:] }
                let count = Int(sqlite3_column_bytes(context, 4))
                let data = Data(bytes: bytes, count: count)
                return (try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]) ?? [:]
            }()
            
            result.append(
                .init(
                    id: id,
                    destination: destination,
                    eventName: eventName,
                    parameters: parameters,
                    timestamp: .init(timeIntervalSince1970: TimeInterval(timestamp)
                    )
                )
            )

        }
        
        let success = delete(result.map(\.id))
        return success ? result : []
    }
    
    public func count() -> Int {
        let query = "SELECT COUNT(*) FROM Events"
        let context = prepare(query: query)
        
        defer {
            sqlite3_finalize(context)
        }
        
        if sqlite3_step(context) != SQLITE_ROW {
            assertionWithLastErrorMessage()
            return 0
        }
        
        let result = Int(sqlite3_column_int64(context, 0))
        
        return result
    }
    
    private func prepare(query: String, option: Int32 = SQLITE_PREPARE_PERSISTENT) -> OpaquePointer? {
        var context: OpaquePointer?
        
        if sqlite3_prepare_v3(
            dbPointer,
            query,
            -1,
            UInt32(option),
            &context,
            nil
        ) != SQLITE_OK {
            assertionWithLastErrorMessage()
        }
        
        return context
    }
    
    private func delete(_ IDs: [String]) -> Bool {
        let query = """
        DELETE FROM Events WHERE \(IDs.map { _ in "id = ?" }.joined(separator:  " OR "))
        """
        
        let context = prepare(query: query)
        
        defer {
            sqlite3_finalize(context)
        }
        
        for (index, id) in IDs.enumerated() {
            if sqlite3_bind_text(context, Int32(index + 1), id.utf8String, -1, nil) != SQLITE_OK {
                assertionWithLastErrorMessage()
                return false
            }
        }
        
        if sqlite3_step(context) != SQLITE_DONE {
            assertionWithLastErrorMessage()
            return false
        } else {
            return true
        }
    }
    
    private func assertionWithLastErrorMessage() {
        let error = String(cString: sqlite3_errmsg(dbPointer))
        assertionFailure("\(error).This is probably a programming error.")
    }
}

extension SQLiteBuffer {
    // for debug
    func clear() {
        let query = "DELETE FROM Events"
        let context = prepare(query: query)

        if sqlite3_step(context) != SQLITE_DONE {
            assertionWithLastErrorMessage()
            return
        }
    }
}

extension String {
    //https://stackoverflow.com/questions/28142226/sqlite-for-swift-is-unstable
    var utf8String: UnsafePointer<CChar>? {
        (self as NSString).utf8String
    }
}
