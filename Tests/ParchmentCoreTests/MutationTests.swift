//
//  MutationTests.swift
//
//
//  Created by Kohei Kawaguchi on 2023/05/18.
//

@testable import ParchmentCore
import XCTest

private struct MutationMock: Mutation, @unchecked Sendable {
    let _transform: ((Loggable, LoggerComponentID) -> AnyLoggable)?

    func transform(_ l: Loggable, id: LoggerComponentID) -> AnyLoggable {
        _transform!(l, id)
    }
}

final class MutationTests: XCTestCase {
    func testTransform() async {
        let mutationA = MutationMock { l, id in
            AnyLoggable(
                eventName: l.eventName,
                parameters: l.parameters.merging(["hoge": 0], uniquingKeysWith: { _, r in
                    r
                })
            )
        }
        let mutationB = MutationMock { l, id in
            AnyLoggable(
                eventName: l.eventName,
                parameters: l.parameters.merging(["fuga": 1], uniquingKeysWith: { _, r in
                    r
                })
            )
        }


        let mutations: [any Mutation] = [mutationA, mutationB]

        let r = await mutations.transform(AnyLoggable(eventName: "", parameters: ["foo": 2]), id: .init(""))

        XCTAssertEqual(
            r.parameters as NSDictionary,
            ["hoge": 0, "fuga": 1, "foo": 2]
        )
    }

    func testTransform_later_is_higher_priority() async {
        let mutationA = MutationMock { l, id in
            AnyLoggable(
                eventName: l.eventName,
                parameters: l.parameters.merging(["hoge": 0], uniquingKeysWith: { _, r in
                    r
                })
            )
        }
        let mutationB = MutationMock { l, id in
            AnyLoggable(
                eventName: l.eventName,
                parameters: l.parameters.merging(["hoge": 1], uniquingKeysWith: { _, r in
                    r
                })
            )
        }


        let mutations: [any Mutation] = [mutationA, mutationB]

        let r = await mutations.transform(AnyLoggable(eventName: "", parameters: ["hoge": ""]), id: .init(""))

        XCTAssertEqual(
            r.parameters as NSDictionary,
            ["hoge": 1]
        )
    }
}
