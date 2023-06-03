//
//  AnyLoggableTests.swift
//  
//
//  Created by Kohei Kawaguchi on 2023/05/23.
//

@testable import ParchmentCore
import XCTest

private struct HogeEvent: Loggable {
    var eventName: String = ""
    var parameters: [String : Sendable] = [:]
}

private struct FugaEvent: Loggable {
    var eventName: String = ""
    var parameters: [String : Sendable] = [:]
}

class AnyLoggableTests: XCTestCase {
    @AnyLoggableActor
    func test_isBased() async throws {
        let e = AnyLoggable(
            AnyLoggable(
                HogeEvent()
            )
        )

        XCTAssertTrue(e.isBased(HogeEvent.self))
        XCTAssertTrue(e.isBased(AnyLoggable.self))
        XCTAssertFalse(e.isBased(FugaEvent.self))
    }
}
