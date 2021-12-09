//
//  RegularlyPollingSchedulerTests.swift
//
//
//  Created by k-kohey on 2021/12/06.
//

import XCTest
@testable import Parchment

private enum Event: Loggable {
    case hoge
    
    var eventName: String {
        switch self {
        case .hoge:
            return "hoge"
        }
    }
    
    var parameters: [String : Any] {
        switch self {
        case .hoge:
            return ["hello": "world"]
        }
    }
}



class MutationTests: XCTestCase {
    // 的確なテストに直す
    func testTransform() throws {
        let event = Event.hoge
        let mutation: [Mutation] = [DeviceDataMutation()]
        
        let newEvent = mutation.transform(event, id: .init("hoge"))
        
        XCTAssertTrue(newEvent.parameters.count > 1)
    }
}
