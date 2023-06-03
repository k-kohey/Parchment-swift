//
//  Payload.swift
//
//
//  Created by k-kohey on 2021/10/08.
//

import Foundation

public struct Payload: Loggable, LoggerSendable, Equatable {
    public let id: String
    public let destination: String
    public let eventName: String
    public let parameters: [String: Sendable]
    public let timestamp: Date

    public init(id: String = UUID().uuidString, destination: String, event: Loggable, timestamp: Date) {
        self.id = id
        self.destination = destination
        eventName = event.eventName
        parameters = event.parameters
        self.timestamp = timestamp
    }

    public init(
        id: String = UUID().uuidString,
        destination: String,
        eventName: String,
        parameters: [String: Sendable],
        timestamp: Date
    ) {
        self.id = id
        self.destination = destination
        self.eventName = eventName
        self.parameters = parameters
        self.timestamp = timestamp
    }

    public static func == (lhs: Payload, rhs: Payload) -> Bool {
        lhs.id == rhs.id
            && lhs.destination == rhs.destination
            && lhs.eventName == rhs.eventName
            && (lhs.parameters as NSDictionary).isEqual(to: rhs.parameters)
            && lhs.timestamp == rhs.timestamp
    }
}

public extension Payload {
    var event: Loggable {
        TrackingEvent(eventName: eventName, parameters: parameters)
    }
}

extension Payload: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(destination, forKey: .destination)
        try container.encode(eventName, forKey: .eventName)
        try container.encode(timestamp, forKey: .timestamp)

        var parametersContainer = container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .parameters)
        try encodeToContainer(value: parameters, container: &parametersContainer)
    }

    private func encodeToContainer(value: Any, container: inout KeyedEncodingContainer<DynamicCodingKeys>) throws {
        for (key, value) in value as! [String: Any] {
            let codingKey = DynamicCodingKeys(key: key)

            switch value {
            case let intValue as Int:
                try container.encode(intValue, forKey: codingKey)
            case let stringValue as String:
                try container.encode(stringValue, forKey: codingKey)
            case let boolValue as Bool:
                try container.encode(boolValue, forKey: codingKey)
            case let doubleValue as Double:
                try container.encode(doubleValue, forKey: codingKey)
            case let floatValue as Float:
                try container.encode(floatValue, forKey: codingKey)
            case let dateValue as Date:
                try container.encode(dateValue, forKey: codingKey)
            case let dataValue as Data:
                try container.encode(dataValue, forKey: codingKey)
            case let arrayValue as [Any]:
                var nestedContainer = container.nestedUnkeyedContainer(forKey: codingKey)
                for item in arrayValue {
                    try encodeToContainer(value: item, container: &nestedContainer)
                }
            case let dictionaryValue as [String: Any]:
                var nestedContainer = container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: codingKey)
                try encodeToContainer(value: dictionaryValue, container: &nestedContainer)
            default:
                try container.encodeNil(forKey: codingKey)
            }
        }
    }

    private func encodeToContainer(value: Any, container: inout UnkeyedEncodingContainer) throws {
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let floatValue as Float:
            try container.encode(floatValue)
        case let dateValue as Date:
            try container.encode(dateValue)
        case let dataValue as Data:
            try container.encode(dataValue)
        case let arrayValue as [Any]:
            var nestedContainer = container.nestedUnkeyedContainer()
            for item in arrayValue {
                try encodeToContainer(value: item, container: &nestedContainer)
            }
        case let dictionaryValue as [String: Any]:
            var nestedContainer = container.nestedContainer(keyedBy: DynamicCodingKeys.self)
            try encodeToContainer(value: dictionaryValue, container: &nestedContainer)
        default:
            try container.encodeNil()
        }
    }
}

extension Payload: Decodable {
    public init(from decoder: Decoder) throws {
        func decodeFromContainer(container: KeyedDecodingContainer<DynamicCodingKeys>) throws -> [String: Any] {
            var result = [String: Any]()
            for key in container.allKeys {
                if let intValue = try? container.decode(Int.self, forKey: key) {
                    result[key.stringValue] = intValue
                } else if let stringValue = try? container.decode(String.self, forKey: key) {
                    result[key.stringValue] = stringValue
                } else if let boolValue = try? container.decode(Bool.self, forKey: key) {
                    result[key.stringValue] = boolValue
                } else if let doubleValue = try? container.decode(Double.self, forKey: key) {
                    result[key.stringValue] = doubleValue
                } else if let floatValue = try? container.decode(Float.self, forKey: key) {
                    result[key.stringValue] = floatValue
                } else if let dateValue = try? container.decode(Date.self, forKey: key) {
                    result[key.stringValue] = dateValue
                } else if let dataValue = try? container.decode(Data.self, forKey: key) {
                    result[key.stringValue] = dataValue
                } else if let nestedDictionary = try? container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: key) {
                    result[key.stringValue] = try decodeFromContainer(container: nestedDictionary)
                } else if var nestedArray = try? container.nestedUnkeyedContainer(forKey: key) {
                    result[key.stringValue] = try decodeFromArrayContainer(container: &nestedArray)
                }
            }
            return result
        }

        func decodeFromArrayContainer(container: inout UnkeyedDecodingContainer) throws -> [Any] {
            var result = [Any]()
            while !container.isAtEnd {
                if let intValue = try? container.decode(Int.self) {
                    result.append(intValue)
                } else if let stringValue = try? container.decode(String.self) {
                    result.append(stringValue)
                } else if let boolValue = try? container.decode(Bool.self) {
                    result.append(boolValue)
                } else if let doubleValue = try? container.decode(Double.self) {
                    result.append(doubleValue)
                } else if let floatValue = try? container.decode(Float.self) {
                    result.append(floatValue)
                } else if let dateValue = try? container.decode(Date.self) {
                    result.append(dateValue)
                } else if let dataValue = try? container.decode(Data.self) {
                    result.append(dataValue)
                } else if let nestedDictionary = try? container.nestedContainer(keyedBy: DynamicCodingKeys.self) {
                    result.append(try decodeFromContainer(container: nestedDictionary))
                } else if var nestedArray = try? container.nestedUnkeyedContainer() {
                    result.append(try decodeFromArrayContainer(container: &nestedArray))
                }
            }
            return result
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        destination = try container.decode(String.self, forKey: .destination)
        eventName = try container.decode(String.self, forKey: .eventName)
        timestamp = try container.decode(Date.self, forKey: .timestamp)

        let parametersContainer = try container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .parameters)
        parameters = try decodeFromContainer(container: parametersContainer)
    }

}

private enum CodingKeys: String, CodingKey {
    case id, destination, eventName, parameters, timestamp
}

private struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    var intValue: Int?
    init?(intValue: Int) {
        return nil
    }

    init(key: String) {
        self.stringValue = key
    }
}
