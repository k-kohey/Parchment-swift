//
//  File.swift
//  
//
//  Created by k-kohey on 2022/12/29.
//

import ArgumentParser
import Foundation
import EventGenKit

@main
struct EventGen: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A Event definision generator.",
        subcommands: [Transpile.self, Prepare.self],
        defaultSubcommand: Execute.self
    )
}


extension EventGen {
    struct RuntimeError: LocalizedError {
        var errorDescription: String?

        init(_ description: String) {
            self.errorDescription = description
        }
    }

    struct Execute: ParsableCommand {

        @Option(name: [.short, .customLong("input")], help: "A Markdown file or directory with event definitions.")
        var inputPth: String

        @Option(name: [.short, .customLong("output")], help: "A Swift file defining the events generated from the intermediate file.")
        var outputPath: String

        mutating func run() throws {
            //TODO: Implemantaion
        }
    }

    struct Transpile: ParsableCommand {
        @Option(name: [.short, .customLong("input")], help: "A Intermediate file with event definitions.")
        var inputPath: String

        @Option(name: [.short, .customLong("output")], help: "A Swift file defining the events generated from the intermediate file.")
        var outputPath: String

        mutating func run() throws {
            guard let input = try? String(contentsOfFile: inputPath).data(using: .utf8) else {
                throw RuntimeError("Couldn't read from '\(inputPath)'!")
            }
            let difinision = try JSONDecoder().decode([EventDefinision].self, from: input)
            let generator = SwiftGenerator()
            let output = try generator.run(with: difinision)

            guard let _ = try? output.write(toFile: outputPath, atomically: true, encoding: .utf8) else {
                throw RuntimeError("Couldn't write to '\(outputPath)'!")
            }
        }
    }

    struct Prepare: ParsableCommand {
        @Option(name: [.short, .customLong("input")], help: "A Markdown file or directory with event definitions.")
        var inputPath: String

        @Option(name: [.short, .customLong("output")], help: "A Intermediate file with event definitions.")
        var outputFile: String

        mutating func run() throws {

            var paths = try FileManager.default
                .contentsOfDirectory(atPath: inputPath)
                .filter { $0.suffix(3) == ".md" }
                .map {
                    "\(inputPath)/\($0)"
                }

            if paths.isEmpty {
                paths = [inputPath]
            }

            if !paths.contains(where: { $0.suffix(3) == ".md" }) {
                throw RuntimeError("Couldn't find path '\(inputPath)'!")
            }

            print(paths)

            guard let inputs = try? paths.map(String.init(contentsOfFile:)) else {
                throw RuntimeError("Couldn't read from '\(inputPath)'!")
            }

            let result = inputs.map(IntermediateFileParser().parse(with:))
            let output = String(
                data: try JSONEncoder().encode(result),
                encoding: .utf8
            )!

            guard let _ = try? output.write(toFile: outputFile, atomically: true, encoding: .utf8) else {
                throw RuntimeError("Couldn't write to '\(outputFile)'!")
            }
        }
    }
}
