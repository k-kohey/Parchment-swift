//
//  IntermediateFileParser.swift
//  
//
//  Created by k-kohey on 2022/12/30.
//

import Foundation
import Markdown

public struct IntermediateFileParser {
    public init() {}
    
    // TODO: Refactor
    public func parse(with source: String) -> EventDefinision {
        let document = Document(parsing: source)


        let sectionBlocks = document.blockChildren.split { block in
            block is Heading
        }
        let headings = document.blockChildren.compactMap { $0 as? Heading }


        let eventName = Array(headings)[0].plainText
        let eventDescription = sectionBlocks[0].compactMap { $0 as? Paragraph }
            .map(\.plainText).joined(separator: "\n")


        let paramertesrBlock =  Array(document.blockChildren
            .compactMap { $0 as? UnorderedList }).first
        let paramerters = paramertesrBlock?.children.compactMap { $0 as? ListItem }

        var fields: [Field] = []
        for paramerter in paramerters ?? [] {
            let paramerterName = (paramerter.child(at: 0) as! Paragraph).plainText
            let options = (paramerter.child(at: 1) as! UnorderedList).children.map { $0 as! ListItem }
                .map {
                    let key = ($0.child(through: [
                        (0, Paragraph.self),
                        (0, Text.self)
                    ]) as! Text).plainText
                    let value = ($0.child(through: [
                        (1, UnorderedList.self),
                        (0, ListItem.self),
                        (0, Paragraph.self),
                        (0, Text.self),
                    ]) as! Text).plainText

                    return [key: value]
                }
                .reduce([String: String].init(), { $0.merging($1, uniquingKeysWith: { _, last in last }) })

            fields.append(
                Field(
                    name: paramerterName,
                    type: options["type"]!,
                    description: options["description"]!,
                    nullable: options["nullable"]! == "true" ? true : false
                )
            )
        }

        let discussion: String
        if 2 < sectionBlocks.count {
            discussion = sectionBlocks[2]
                .compactMap { $0 as? Paragraph }
                .map(\.plainText)
                .joined(separator: "\n")
        } else {
            discussion = ""
        }

        return EventDefinision(
            name: eventName,
            properties: fields,
            description: eventDescription,
            discussion: discussion
        )
    }
}
