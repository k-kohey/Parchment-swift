//
//  SwiftGeneratorTests.swift
//  
//
//  Created by k-kohey on 2022/12/30.
//

import XCTest
@testable import EventGenKit

final class SwiftGeneratorTests: XCTestCase {

    func testRun() throws {
        let generator = SwiftGenerator()
        let input = """
        [
           {
              "properties":[

              ],
              "name":"firstLaunch",
              "description":"Event sent when the user launches the application for the first time．",
              "discussion":""
           },
           {
              "properties":[
                 {
                    "nullable":false,
                    "name":"screenName",
                    "type":"string",
                    "description":"the displayed screen name"
                 },
                 {
                    "nullable":true,
                    "name":"count",
                    "type":"int",
                    "description":"If this screen has been displayed in the past, indicate how many times it has been displayed"
                 }
              ],
              "name":"impression",
              "description":"This event is automatically sent by the system when any screen is displayed．",
              "discussion":"This event was called `shown` in the past"
           }
        ]
        """.data(using: .utf8)!

        let def = try JSONDecoder().decode([EventDefinision].self, from: input)
        let result = try generator.run(with: def)

        let expected = """
        import Parchment
        struct GeneratedEvent: Loggable {
            let eventName: String
            let parameters: [String: Sendable]
        }
        extension GeneratedEvent {
            /// Event sent when the user launches the application for the first time．
            static var firstLaunch: Self {
                GeneratedEvent(eventName: "firstLaunch", parameters: [: ])
            }
            /// This event is automatically sent by the system when any screen is displayed．
            /// - Parameters:
            ///   - screenName: the displayed screen name
            ///   - count: If this screen has been displayed in the past, indicate how many times it has been displayed
            static func impression(screenName: String?, count: Int) -> Self {
                GeneratedEvent(eventName: "impression", parameters: ["screenName": screenName, "count": count])
            }
        }
        """

        XCTAssertEqual(
            // TODO: remove unneeded space and newlines
            result.trimmingCharacters(in: .whitespacesAndNewlines),
            expected
        )
    }
}
