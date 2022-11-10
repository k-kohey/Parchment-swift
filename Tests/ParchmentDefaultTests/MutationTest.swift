//
//  RegularlyPollingSchedulerTests.swift
//
//
//  Created by k-kohey on 2021/12/06.
//

@testable import Parchment
@testable import ParchmentDefault
import XCTest

private enum Event: Loggable {
    case hoge

    var eventName: String {
        switch self {
        case .hoge:
            return "hoge"
        }
    }

    var parameters: [String: Any] {
        switch self {
        case .hoge:
            return ["hello": "world"]
        }
    }
}

class MutationTests: XCTestCase {
    // 的確なテストに直す
    @MainActor func testTransform() throws {
        let event = Event.hoge
        let mutation: [Mutation] = [DeviceDataMutation(device: .current)]

        let newEvent = mutation.transform(event, id: .init("hoge"))

        XCTAssertTrue(newEvent.parameters.count > 1)
    }
}
