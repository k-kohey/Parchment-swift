//
//  TransformTests.swift
//  
//
//  Created by Kohei Kawaguchi on 2023/05/18.
//

@testable import Parchment
import XCTest

private struct MutationMock: Mutation {
    var _transform: Transform?
    func transform(_ l: Loggable, id: LoggerComponentID) -> Loggable {
        _transform!(l, id)
    }

    init(_transform: Transform? = nil) {
        self._transform = _transform
    }
}

final class TransformTests: XCTestCase {
    func testComposed() {
        let mutationA = MutationMock { l, id in
            TrackingEvent(
                eventName: l.eventName,
                parameters: l.parameters.merging(["hoge": 0], uniquingKeysWith: { _, r in
                    r
                })
            )
        }
        let mutationB = MutationMock { l, id in
            TrackingEvent(
                eventName: l.eventName,
                parameters: l.parameters.merging(["fuga": 1], uniquingKeysWith: { _, r in
                    r
                })
            )
        }


        let mutations: [any Mutation] = [mutationA, mutationB]
        let r = mutations.composed()(TrackingEvent(eventName: "", parameters: ["foo": 2]), .init(""))

        XCTAssertEqual(
            r.parameters as NSDictionary,
            ["hoge": 0, "fuga": 1, "foo": 2]
        )
    }
}
