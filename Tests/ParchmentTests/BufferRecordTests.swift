//
//  BufferRecordTests.swift
//  
//
//  Created by Kohei Kawaguchi on 2023/05/20.
//

import XCTest
@testable import Parchment

class BufferRecordTests: XCTestCase {
    func testEncodeAndDecode() throws {
        let originalRecord = BufferRecord(
            id: "id1",
            destination: "dest1",
            eventName: "event1",
            parameters: [
                "key1": "value1",
                "key2": 123,
                "key3": ["subkey1": "subvalue1"],
                "key4": ["1", "2", "3"],
                "key5": Date(timeIntervalSince1970: 0),
                "key6": Data("testdata".utf8),
                "key7": 123.4,
            ],
            timestamp: Date(timeIntervalSince1970: 0)
        )

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"

        // Encoding
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.dataEncodingStrategy = .deferredToData
        let data = try encoder.encode(originalRecord)

        // Decoding
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.dataDecodingStrategy = .deferredToData
        let decodedRecord = try decoder.decode(BufferRecord.self, from: data)

        // Check equality
        XCTAssertEqual(originalRecord.id, decodedRecord.id)
        XCTAssertEqual(originalRecord.destination, decodedRecord.destination)
        XCTAssertEqual(originalRecord.eventName, decodedRecord.eventName)
        XCTAssertEqual(originalRecord.timestamp, decodedRecord.timestamp)
        XCTAssertEqual(originalRecord.parameters as NSDictionary, decodedRecord.parameters as NSDictionary)
    }
}
