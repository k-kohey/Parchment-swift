//
//  DeviceDataMutationTests.swift
//
//
//  Created by k-kohey on 2021/12/06.
//

@testable import Parchment
import XCTest

private enum Event: Loggable {
    case hoge

    var eventName: String {
        switch self {
        case .hoge:
            return "hoge"
        }
    }

    var parameters: [String: Sendable] {
        switch self {
        case .hoge:
            return ["hello": "world"]
        }
    }
}

#if canImport(UIKit)
class DeviceDataMutationTests: XCTestCase {
    // 的確なテストに直す
    @MainActor func testTransform() async throws {
        let event = Event.hoge
        let mutation: [Mutation] = [DeviceDataMutation(device: .current)]

        let newEvent = await mutation.transform(event, id: .init("hoge"))

        XCTAssertTrue(newEvent.parameters.count > 1)
    }
}
#endif
