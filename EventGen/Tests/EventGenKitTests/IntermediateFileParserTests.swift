//
//  IntermediateFileParser.swift
//  
//
//  Created by Kohei Kawaguchi on 2022/12/30.
//

import XCTest
@testable import EventGenKit

final class IntermediateFileParserTests: XCTestCase {
    func testParse() {
        let input = """
        # impression

        This event is automatically sent by the system when any screen is displayed．

        ## Parameters

        - screenName
          - type
            - string
          - nullable
            - false
          - description
            - the displayed screen name
        - count
          - type
            - int
          - nullable
            - true
          - description
            - If this screen has been displayed in the past, indicate how many times it has been displayed

        ## Discussion

        This event was called `shown` in the past

        """

        let parser = IntermediateFileParser()
        let result = parser.parse(with: input)

        XCTAssertEqual(
            result,
            .init(
                name: "impression",
                properties: [
                    .init(
                        name: "screenName",
                        type: "string",
                        description: "the displayed screen name",
                        nullable: false
                    ),
                    .init(
                        name: "count",
                        type: "int",
                        description: "If this screen has been displayed in the past, indicate how many times it has been displayed",
                        nullable: true
                    )
                ],
                description: "This event is automatically sent by the system when any screen is displayed．",
                discussion: "This event was called `shown` in the past"
            )
        )
    }
}
