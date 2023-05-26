//
//  File.swift
//  
//
//  Created by k-kohey on 2022/12/30.
//

import Foundation
import Parchment
import SwiftSyntax
import SwiftSyntaxBuilder

struct GeneratedEvent: Loggable {
    let eventName: String
    let parameters: [String : Sendable]

    static func token<T>(_ keyPath: KeyPath<Self, T>) -> TokenSyntax {
        switch keyPath {
        case \.eventName:
            return .identifier("eventName")
        case \.parameters:
            return .identifier("parameters")
        default:
            fatalError()
        }
    }

    static func identifierPattern<T>(
        _ keyPath: KeyPath<Self, T>
    ) -> IdentifierPatternSyntax {
        switch keyPath {
        case \.eventName:
            return "eventName"
        case \.parameters:
            return "parameters"
        default:
            fatalError()
        }
    }
}

public struct SwiftGenerator {
    enum Error: Swift.Error {
        case argumentsIsEmpty
    }

    public init() {

    }

    public func run(with definisions: [EventDefinision]) throws -> String {
        guard !definisions.isEmpty else { throw Error.argumentsIsEmpty }
        return generate(with: definisions)
    }

    private func generate(with definisions: [EventDefinision]) -> String {
        SourceFileSyntax {
            ImportDeclSyntax(path: [.init(name: "Parchment")])
            generatedEventStructDecl
            extensionDecl(with: definisions)
        }.formatted().description
    }

    private var generatedEventStructDecl: StructDeclSyntax {
        StructDeclSyntax(
            identifier: "\(GeneratedEvent.self)",
            inheritanceClause: TypeInheritanceClauseSyntax {
                InheritedTypeSyntax(
                    typeName: SimpleTypeIdentifierSyntax(
                        stringLiteral: "\(Loggable.self)"
                    )
                )
            }
        ) {
            VariableDeclSyntax(
                .let,
                name: GeneratedEvent.identifierPattern(\.eventName),
                type: TypeAnnotationSyntax(
                    type: SimpleTypeIdentifierSyntax(stringLiteral: "\(String.self)")
                )
            )
            VariableDeclSyntax(
                .let,
                name: GeneratedEvent.identifierPattern(\.parameters),
                type: TypeAnnotationSyntax(
                    type: DictionaryTypeSyntax(
                        keyType: SimpleTypeIdentifierSyntax(
                            stringLiteral: "\(String.self)"
                        ),
                        valueType: SimpleTypeIdentifierSyntax(
                            stringLiteral: "Sendable"
                        )
                    )
                )
            )
        }
    }

    private func extensionDecl(with definisions: [EventDefinision]) -> ExtensionDeclSyntax {
        ExtensionDeclSyntax(
            extendedType: SimpleTypeIdentifierSyntax(
                stringLiteral: "\(GeneratedEvent.self)"
            )
        ) {
            for definision in definisions {
                if definision.properties.isEmpty {
                    propertyEventDecl(with: definision)
                } else {
                    functionEventDecl(with: definision)
                }

            }
        }
    }

    private func propertyEventDecl(with definision: EventDefinision) -> VariableDeclSyntax {
        VariableDeclSyntax(
            leadingTrivia: .init(
                pieces: generateCodeDocument(with: definision)
            ),
            modifiers: ModifierListSyntax {
                DeclModifierSyntax(name: .static)
            },
            name: .init(stringLiteral: definision.name),
            type: TypeAnnotationSyntax(
                type: SimpleTypeIdentifier(stringLiteral: "Self")
            )
        ) {
            generatedEventInitialization(with: definision)
        }
    }

    private func functionEventDecl(
        with definision: EventDefinision
    ) -> FunctionDeclSyntax {
        FunctionDeclSyntax(
            leadingTrivia: .init(
                pieces: generateCodeDocument(with: definision)
            ),
            modifiers: ModifierListSyntax {
                DeclModifierSyntax(name: .static)
            },
            identifier: .identifier(definision.name),
            signature: FunctionSignatureSyntax(
                input: ParameterClauseSyntax {
                    for property in definision.properties {
                        FunctionParameterSyntax(
                            firstName: .identifier(property.name),
                            colon: .colon,
                            type: typeSyntax(
                                property.type, isNullable: property.nullable
                            )
                        )
                    }
                },
                output: ReturnClause(
                    returnType: SimpleTypeIdentifierSyntax(
                        stringLiteral: "Self"
                    )
                )
            )
        ) {
            functionEventBodyDecl(with: definision)
        }
    }

    private func functionEventBodyDecl(with definision: EventDefinision) -> CodeBlockItemListSyntax {
        CodeBlockItemListSyntax {
            generatedEventInitialization(with: definision)
        }
    }

    private func generatedEventInitialization(
        with definision: EventDefinision
    ) -> FunctionCallExprSyntax {
        FunctionCallExprSyntax(
            callee: IdentifierExprSyntax(stringLiteral: "\(GeneratedEvent.self)")
        ) {
            TupleExprElementSyntax(
                label: GeneratedEvent.token(\.eventName),
                colon: .colon,
                expression: StringLiteralExprSyntax(
                    content: definision.name
                )
            )
            TupleExprElementSyntax(
                label: GeneratedEvent.token(\.parameters),
                colon: .colon,
                expression: DictionaryExprSyntax {
                    for property in definision.properties {
                        DictionaryElementSyntax.init(
                            keyExpression: StringLiteralExprSyntax(
                                content: property.name
                            ),
                            valueExpression: IdentifierExpr(stringLiteral: property.name)
                        )
                    }
                }
            )
        }
    }

    private func generateCodeDocument(with definision: EventDefinision) -> [TriviaPiece] {
        if !definision.properties.isEmpty {
            var result: [TriviaPiece] =  [
                .docLineComment("/// \(definision.description)"),
                .newlines(1),
                .docLineComment("/// - Parameters:"),
                .newlines(1)
            ]

            for property in definision.properties {
                result.append(
                    .docLineComment("///   - \(property.name): \(property.description)")
                )
                result.append(.newlines(1))
            }

            return result
        } else {
            return [
                .docLineComment("/// \(definision.description)"),
                .newlines(1)
            ]
        }
    }

    private func typeSyntax(_ typeString: String, isNullable: Bool) -> TypeSyntaxProtocol {
        func type(_ typeString: String, isNullable: Bool) -> String {
            switch typeString {
            case "string":
                return "\(String.self)"
            case "int":
                return "\(Int.self)"
            case "double":
                return "\(Double.self)"
            case "boolean":
                return "\(Bool.self)"
            default:
                fatalError("Detect unsupported type \(typeString)")
            }
        }

        let simpleSyntax = SimpleTypeIdentifierSyntax(
                stringLiteral: type(
                    typeString, isNullable: isNullable
                )
            )
        if isNullable {
            return simpleSyntax
        } else {
            return OptionalTypeSyntax(wrappedType: simpleSyntax)
        }
    }
}

private extension DefaultStringInterpolation {
    mutating func appendInterpolation(indented string: String) {
       let indent = String(stringInterpolation: self).reversed().prefix { " \t".contains($0) }
       if indent.isEmpty {
            appendInterpolation(string)
        } else {
            appendLiteral(string.split(separator: "\n", omittingEmptySubsequences: false).joined(separator: "\n" + indent))
        }
    }
}
