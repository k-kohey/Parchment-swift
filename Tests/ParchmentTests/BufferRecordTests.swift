//
//  BufferRecordTests.swift
//  
//
//  Created by Kohei Kawaguchi on 2023/05/20.
//

import XCTest
@testable import Parchment

class BufferRecordTests: XCTestCase {
    func testEcode() throws {
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

            // Encoding
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(originalRecord)

            // Convert encoded data to a JSON string
            let jsonString = String(data: data, encoding: .utf8)

            // Define the expected JSON string
            let expectedJSONString = """
            {
                "id": "id1",
                "destination": "dest1",
                "timestamp": "1970-01-01T00:00:00Z",
                "eventName": "event1",
                "parameters": {
                    "key5": "1970-01-01T00:00:00Z",
                    "key2": 123,
                    "key6": "dGVzdGRhdGE=",
                    "key3": {
                        "subkey1": "subvalue1"
                    },
                    "key7": 123.40000000000001,
                    "key4": ["1","2","3"],
                    "key1": "value1"
                }
            }
            """
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")

            // Compare the encoded JSON string with the expected JSON string
        XCTAssertEqual(jsonString, expectedJSONString)
    }

    func testDecode() throws {
        let jsonString = """
        {
            "id": "id1",
            "destination": "dest1",
            "timestamp": "1970-01-01T00:00:00Z",
            "eventName": "event1",
            "parameters": {
                "key5": "1970-01-01T00:00:00Z",
                "key2": 123,
                "key6": "dGVzdGRhdGE=",
                "key3": {
                    "subkey1": "subvalue1"
                },
                "key7": 123.40000000000001,
                "key4": ["1","2","3"],
                "key1": "value1"
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let result = try decoder.decode(BufferRecord.self, from: jsonString)

        print(dump(result))

        XCTAssertEqual(
            result,
            BufferRecord(
                    id: "id1",
                    destination: "dest1",
                    eventName: "event1",
                    parameters: [
                        "key1": "value1",
                        "key2": 123,
                        "key3": ["subkey1": "subvalue1"],
                        "key4": ["1", "2", "3"],
                        "key5": "1970-01-01T00:00:00Z",
                        "key6": "dGVzdGRhdGE=",
                        "key7": 123.4,
                    ],
                    timestamp: Date(timeIntervalSince1970: 0)
                )
        )
    }
}
